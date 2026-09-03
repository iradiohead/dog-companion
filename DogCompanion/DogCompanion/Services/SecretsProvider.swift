import Foundation

enum SecretsProvider {
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

    static var replicateModel: String {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any],
            let model = dictionary["REPLICATE_MODEL"] as? String,
            !model.isEmpty
        else {
            return "chigozienri/ip_adapter-sdxl"
        }
        return model
    }
}
