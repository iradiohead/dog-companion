import Foundation
import UIKit

enum GenerationError: LocalizedError {
    case missingAPIToken
    case invalidImage
    case networkError(String)
    case generationFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIToken:
            return "未配置 Replicate API Token。请复制 Secrets.plist.example 为 Secrets.plist 并填入密钥。"
        case .invalidImage:
            return "无法读取照片，请换一张试试。"
        case .networkError(let message):
            return "网络错误：\(message)"
        case .generationFailed(let message):
            return "生成失败：\(message)"
        case .invalidResponse:
            return "服务器返回了无效数据，请稍后重试。"
        }
    }
}

struct GenerationService {
    private let session: URLSession
    private let maxRetries = 2

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

        var lastError: Error = GenerationError.generationFailed("未知错误")

        for attempt in 0...maxRetries {
            do {
                return try await performGeneration(
                    imageData: jpegData,
                    style: style,
                    token: token
                )
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * (attempt + 1)))
                }
            }
        }

        throw lastError
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
        let url = URL(string: "https://api.replicate.com/v1/models/\(SecretsProvider.replicateModel)/predictions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "input": [
                "image": imageURI,
                "prompt": style.prompt,
                "negative_prompt": style.negativePrompt,
                "num_outputs": 1,
                "num_inference_steps": 30
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let id = json["id"] as? String
        else {
            throw GenerationError.invalidResponse
        }

        return id
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
        let (data, response) = try await session.data(from: url)
        try validateHTTP(response: response, data: data)
        return data
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw GenerationError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw GenerationError.networkError(message)
        }
    }
}
