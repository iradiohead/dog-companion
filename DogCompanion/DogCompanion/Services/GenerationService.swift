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
            return "未配置 Replicate API Token。请复制 Secrets.plist.example 为 Secrets.plist 并填入密钥。"
        case .invalidImage:
            return "无法读取照片，请换一张试试。"
        case .networkError(let message):
            return message
        case .rateLimited(let retryAfter):
            return "请求过于频繁，请约 \(retryAfter) 秒后再试。也可在 replicate.com 账户绑定付款方式以提高限额。"
        case .generationFailed(let message):
            return "生成失败：\(message)"
        case .invalidResponse:
            return "服务器返回了无效数据，请稍后重试。"
        }
    }
}

struct GenerationService {
    private let session: URLSession
    private let maxRateLimitRetries = 3
    private let rateLimitBufferSeconds: TimeInterval = 1
    private static var cachedModelVersion: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateComicPortrait(from image: UIImage, style: StyleTemplate) async throws -> Data {
        guard let token = SecretsProvider.replicateAPIToken else {
            throw GenerationError.missingAPIToken
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw GenerationError.invalidImage
        }

        return try await performGeneration(
            imageData: jpegData,
            style: style,
            token: token
        )
    }

    private func performGeneration(imageData: Data, style: StyleTemplate, token: String) async throws -> Data {
        let base64 = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64)"

        let predictionID = try await createPrediction(
            imageURI: dataURI,
            style: style,
            token: token
        )

        let outputURL = try await pollPrediction(id: predictionID, token: token)
        return try await downloadImage(from: outputURL)
    }

    private func createPrediction(imageURI: String, style: StyleTemplate, token: String) async throws -> String {
        let version = try await resolveModelVersion(token: token)
        let url = URL(string: "https://api.replicate.com/v1/predictions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "version": version,
            "input": [
                "image": imageURI,
                "prompt": style.prompt,
                "negative_prompt": style.negativePrompt,
                "num_outputs": 1,
                "num_inference_steps": 30
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        var lastRateLimitError: GenerationError?

        for attempt in 0..<maxRateLimitRetries {
            let (data, response) = try await session.data(for: request)

            do {
                try validateHTTP(response: response, data: data)
            } catch let error as GenerationError {
                if case .rateLimited(let retryAfter) = error {
                    lastRateLimitError = error
                    guard attempt < maxRateLimitRetries - 1 else {
                        throw error
                    }
                    let waitSeconds = TimeInterval(retryAfter) + rateLimitBufferSeconds
                    try await Task.sleep(nanoseconds: UInt64(waitSeconds * 1_000_000_000))
                    continue
                }
                throw error
            }

            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let id = json["id"] as? String
            else {
                throw GenerationError.invalidResponse
            }

            return id
        }

        throw lastRateLimitError ?? GenerationError.generationFailed("创建生成任务失败")
    }

    private func resolveModelVersion(token: String) async throws -> String {
        if let cached = Self.cachedModelVersion {
            return cached
        }

        let configuredVersion = SecretsProvider.replicateModelVersion
        if !configuredVersion.isEmpty {
            Self.cachedModelVersion = configuredVersion
            return configuredVersion
        }

        let slug = SecretsProvider.replicateModelSlug
        let url = URL(string: "https://api.replicate.com/v1/models/\(slug)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let latestVersion = json["latest_version"] as? [String: Any],
            let version = latestVersion["id"] as? String
        else {
            throw GenerationError.generationFailed("无法获取模型版本，请检查 REPLICATE_MODEL 配置。")
        }

        Self.cachedModelVersion = version
        return version
    }

    private func pollPrediction(id: String, token: String) async throws -> URL {
        let url = URL(string: "https://api.replicate.com/v1/predictions/\(id)")!

        for _ in 0..<60 {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await session.data(for: request)
            try validateHTTP(response: response, data: data)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw GenerationError.invalidResponse
            }

            let status = json["status"] as? String ?? ""

            switch status {
            case "succeeded":
                return try extractOutputURL(from: json)
            case "failed", "canceled":
                let detail = (json["error"] as? String) ?? "生成过程出错"
                throw GenerationError.generationFailed(detail)
            default:
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        throw GenerationError.generationFailed("生成超时，请稍后重试")
    }

    private func extractOutputURL(from json: [String: Any]) throws -> URL {
        if let outputString = json["output"] as? String, let url = URL(string: outputString) {
            return url
        }

        if let outputArray = json["output"] as? [String], let first = outputArray.first, let url = URL(string: first) {
            return url
        }

        throw GenerationError.invalidResponse
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
            let retryAfter = parseRetryAfter(from: data)
            throw GenerationError.rateLimited(retryAfter: retryAfter)
        }

        if http.statusCode == 404 {
            throw GenerationError.generationFailed(
                "Replicate 模型未找到（404）。请检查 Secrets.plist 中的 REPLICATE_MODEL 是否正确。"
            )
        }

        if http.statusCode == 402 {
            throw GenerationError.generationFailed(
                "Replicate 账户余额不足。请前往 replicate.com/account/billing 充值，等待几分钟后重试。"
            )
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw GenerationError.networkError("网络错误：\(message)")
        }
    }

    private func parseRetryAfter(from data: Data) -> Int {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return 6
        }

        if let seconds = json["retry_after"] as? Int {
            return max(1, seconds)
        }

        if let seconds = json["retry_after"] as? Double {
            return max(1, Int(seconds.rounded(.up)))
        }

        return 6
    }
}
