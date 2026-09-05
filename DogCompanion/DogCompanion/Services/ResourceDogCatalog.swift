import Foundation

enum ResourceDogError: LocalizedError {
    case missingResourceRoot
    case dogNotFound(String)
    case missingOriginal(String)
    case invalidImage(String)

    var errorDescription: String? {
        switch self {
        case .missingResourceRoot:
            return "未找到 resource 目录，请确认已加入 App Bundle。"
        case .dogNotFound(let name):
            return "未找到狗狗资源：\(name)"
        case .missingOriginal(let name):
            return "「\(name)」缺少 hand-drawn 图片，且目录里没有可作为原图的图片（需为非 hand-drawn、非 foreground-dog 开头的图片文件）。"
        case .invalidImage(let name):
            return "无法读取「\(name)」的图片文件。"
        }
    }
}

struct ResourceDogCatalog {
    static let resourceFolderName = "resource"
    private static let imageExtensions = Set(["png", "jpg", "jpeg", "heic"])

    var bundle: Bundle = .main
    /// Override in tests to point at a temporary `resource/` tree.
    var resourceRootOverride: URL?

    func resourceRootURL() throws -> URL {
        if let resourceRootOverride {
            return resourceRootOverride
        }
        if let url = bundle.url(forResource: Self.resourceFolderName, withExtension: nil),
           FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        if let resourceURL = bundle.resourceURL {
            let nested = resourceURL.appendingPathComponent(Self.resourceFolderName, isDirectory: true)
            if FileManager.default.fileExists(atPath: nested.path) {
                return nested
            }
        }
        throw ResourceDogError.missingResourceRoot
    }

    func availableDogNames() -> [String] {
        guard let root = try? resourceRootURL() else { return [] }
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents.compactMap { url -> String? in
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  values.isDirectory == true else { return nil }
            return url.lastPathComponent
        }
        .sorted()
    }

    func folderURL(for dogName: String) throws -> URL {
        let url = try resourceRootURL().appendingPathComponent(dogName, isDirectory: true)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ResourceDogError.dogNotFound(dogName)
        }
        return url
    }

    func latestFile(in folderURL: URL, prefix: String) -> URL? {
        imageFiles(in: folderURL)
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
    }

    /// Any image in the folder that does **not** start with `hand-drawn` or `foreground-dog`
    /// is treated as the original photo (e.g. `金毛寻回犬.jpg`).
    func originalImageURL(in folderURL: URL) -> URL? {
        imageFiles(in: folderURL)
            .filter { !Self.isGeneratedAsset(fileName: $0.lastPathComponent) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
    }

    func previewImageURL(for dogName: String) -> URL? {
        guard let folderURL = try? folderURL(for: dogName) else { return nil }
        if let handDrawn = latestFile(in: folderURL, prefix: "hand-drawn") {
            return handDrawn
        }
        if let original = originalImageURL(in: folderURL) {
            return original
        }
        return latestFile(in: folderURL, prefix: "foreground-dog")
    }

    private static func isGeneratedAsset(fileName: String) -> Bool {
        let lower = fileName.lowercased()
        return lower.hasPrefix("hand-drawn") || lower.hasPrefix("foreground-dog")
    }

    private func imageFiles(in folderURL: URL) -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents.filter { Self.imageExtensions.contains($0.pathExtension.lowercased()) }
    }
}
