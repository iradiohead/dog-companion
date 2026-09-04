import Foundation
import UIKit

enum GenerationError: LocalizedError {
    case missingAPIToken
    case invalidImage
    case networkError(String)
    case rateLimited(retryAfter: Int)
    case generationFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIToken:
            return "未配置阿里云百炼 API Key。请复制 Secrets.plist.example 为 Secrets.plist 并填入 DASHSCOPE_API_KEY。"
        case .invalidImage:
            return "无法读取照片，请换一张试试。"
        case .networkError(let message):
            return message
        case .rateLimited(let retryAfter):
            return "请求过于频繁，请约 \(retryAfter) 秒后再试。"
        case .generationFailed(let message):
            return "生成失败：\(message)"
        case .invalidResponse:
            return "服务器返回了无效数据，请稍后重试。"
        }
    }
}

struct GenerationResult {
    let comicPortraitData: Data
    let cutoutData: Data
    let cutoutRunAData: Data?
    let cutoutRunBData: Data?
    let cutoutLandData: Data?
}

struct GenerationService {
    private let session: URLSession
    private let mattingService: MattingService

    init(session: URLSession = .shared, mattingService: MattingService = MattingService()) {
        self.session = session
        self.mattingService = mattingService
    }

    func generateCompanionAssets(from image: UIImage, style: StyleTemplate) async throws -> GenerationResult {
        let portraitData = try await generateComicPortrait(from: image, style: style, pose: .sit)
        guard let portraitImage = UIImage(data: portraitData) else {
            throw GenerationError.invalidImage
        }

        let cutoutData = try await mattingService.extractCutout(from: portraitImage)
        let extras = await generateActionPoses(from: portraitImage, style: style)
        return GenerationResult(
            comicPortraitData: portraitData,
            cutoutData: cutoutData,
            cutoutRunAData: extras.runA,
            cutoutRunBData: extras.runB,
            cutoutLandData: extras.land
        )
    }

    func generateComicPortrait(from image: UIImage, style: StyleTemplate, pose: CompanionPose = .sit) async throws -> Data {
        guard let apiKey = SecretsProvider.dashScopeAPIKey else {
            throw GenerationError.missingAPIToken
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw GenerationError.invalidImage
        }

        let imageURL = try await createWanxiangImage(
            imageData: jpegData,
            style: style,
            pose: pose,
            apiKey: apiKey
        )
        return try await downloadImage(from: imageURL)
    }

    private func generateActionPoses(from sitImage: UIImage, style: StyleTemplate) async -> (runA: Data?, runB: Data?, land: Data?) {
        async let runA = optionalPoseCutout(from: sitImage, style: style, pose: .runA)
        async let runB = optionalPoseCutout(from: sitImage, style: style, pose: .runB)
        async let land = optionalPoseCutout(from: sitImage, style: style, pose: .land)
        return await (runA, runB, land)
    }

    private func optionalPoseCutout(from image: UIImage, style: StyleTemplate, pose: CompanionPose) async -> Data? {
        do {
            let portrait = try await generateComicPortrait(from: image, style: style, pose: pose)
            guard let poseImage = UIImage(data: portrait) else { return nil }
            return try await mattingService.extractCutout(from: poseImage)
        } catch {
            return nil
        }
    }

    private func createWanxiangImage(
        imageData: Data,
        style: StyleTemplate,
        pose: CompanionPose,
        apiKey: String
    ) async throws -> URL {
        let base64 = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64)"

        let endpoint = "\(SecretsProvider.dashScopeBaseURL)/api/v1/services/aigc/multimodal-generation/generation"
        guard let url = URL(string: endpoint) else {
            throw GenerationError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": SecretsProvider.dashScopeModel,
            "input": [
                "messages": [
                    [
                        "role": "user",
                        "content": [
                            ["text": style.prompt(for: pose)],
                            ["image": dataURI]
                        ]
                    ]
                ]
            ],
            "parameters": [
                "negative_prompt": style.negativePrompt,
                "enable_interleave": false,
                "n": 1,
                "size": "1K",
                "watermark": false,
                "prompt_extend": true
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)

        if let apiError = parseAPIError(from: data) {
            throw apiError
        }

        return try extractImageURL(from: data)
    }

    private func extractImageURL(from data: Data) throws -> URL {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GenerationError.invalidResponse
        }

        guard
            let output = json["output"] as? [String: Any],
            let choices = output["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? [[String: Any]]
        else {
            throw GenerationError.invalidResponse
        }

        for item in content {
            if let imageString = item["image"] as? String, let url = URL(string: imageString) {
                return url
            }
        }

        throw GenerationError.invalidResponse
    }

    private func parseAPIError(from data: Data) -> GenerationError? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let code = json["code"] as? String,
            let message = json["message"] as? String
        else {
            return nil
        }

        switch code {
        case "Throttling", "Throttling.RateQuota":
            return .rateLimited(retryAfter: 10)
        case "Arrearage", "InsufficientQuota", "QuotaExceeded":
            return .generationFailed("阿里云百炼额度不足。新用户可在百炼控制台领取 50 张免费额度，或前往充值后重试。")
        case "InvalidApiKey", "AuthenticationError":
            return .generationFailed("API Key 无效，请检查 Secrets.plist 中的 DASHSCOPE_API_KEY。")
        default:
            return .generationFailed("\(message)")
        }
    }

    private func downloadImage(from url: URL) async throws -> Data {
        var lastError: Error = GenerationError.invalidResponse

        for attempt in 0..<2 {
            do {
                let (data, response) = try await session.data(from: url)
                try validateHTTP(response: response, data: data)
                return data
            } catch {
                lastError = error
                if attempt == 0 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }

        throw lastError
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw GenerationError.invalidResponse
        }

        if http.statusCode == 429 {
            throw GenerationError.rateLimited(retryAfter: 10)
        }

        if http.statusCode == 401 {
            throw GenerationError.generationFailed("API Key 无效或未授权，请检查 DASHSCOPE_API_KEY。")
        }

        if http.statusCode == 402 || http.statusCode == 403 {
            throw GenerationError.generationFailed("阿里云百炼额度不足或权限受限，请前往百炼控制台检查余额与权限。")
        }

        guard (200...299).contains(http.statusCode) else {
            if let apiError = parseAPIError(from: data) {
                throw apiError
            }
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw GenerationError.networkError("网络错误：\(message)")
        }
    }
}
