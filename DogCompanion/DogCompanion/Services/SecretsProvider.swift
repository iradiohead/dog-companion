import Foundation

enum SecretsProvider {
    private static let defaultModelSlug = "chigozienri/ip_adapter-sdxl"
    private static let defaultModelVersion = "7a8ccb5aa6da0e63cb24bc68a1f668c012c0088fb3031adc47577085c8d2f606"

    static var replicateAPIToken: String? {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any],
            let token = dictionary["REPLICATE_API_TOKEN"] as? String,
            !token.isEmpty,
            token != "YOUR_TOKEN_HERE"
        else {
            return nil
        }
        return token
    }

    /// Model slug only, e.g. `chigozienri/ip_adapter-sdxl`
    static var replicateModelSlug: String {
        let raw = replicateModelRaw
        if let colonIndex = raw.firstIndex(of: ":") {
            return String(raw[..<colonIndex])
        }
        return raw
    }

    /// Pinned version hash from Secrets.plist, inline `owner/model:version`, or default.
    static var replicateModelVersion: String {
        if let pinned = secretsValue(for: "REPLICATE_MODEL_VERSION"), !pinned.isEmpty {
            return pinned
        }

        let raw = replicateModelRaw
        if let colonIndex = raw.firstIndex(of: ":") {
            let version = String(raw[raw.index(after: colonIndex)...])
            if !version.isEmpty {
                return version
            }
        }

        return defaultModelVersion
    }

    private static var replicateModelRaw: String {
        guard
            let model = secretsValue(for: "REPLICATE_MODEL"),
            !model.isEmpty
        else {
            return defaultModelSlug
        }
        return model
    }

    private static func secretsValue(for key: String) -> String? {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any],
            let value = dictionary[key] as? String
        else {
            return nil
        }
        return value
    }
}
