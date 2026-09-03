import Foundation

enum SecretsProvider {
    static var dashScopeAPIKey: String? {
        guard
            let key = secretsValue(for: "DASHSCOPE_API_KEY"),
            !key.isEmpty,
            key != "YOUR_API_KEY_HERE"
        else {
            return nil
        }
        return key
    }

    static var dashScopeBaseURL: String {
        let raw = secretsValue(for: "DASHSCOPE_BASE_URL") ?? "https://dashscope.aliyuncs.com"
        return raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    static var dashScopeModel: String {
        secretsValue(for: "DASHSCOPE_MODEL") ?? "wan2.6-image"
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
