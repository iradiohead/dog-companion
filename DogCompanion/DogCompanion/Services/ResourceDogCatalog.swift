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
            return "「\(name)」缺少 hand-drawn 图片，且没有原图（original.jpg/png 或其他非生成图）。"
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

    func originalImageURL(in folderURL: URL) -> URL? {
        for name in ["original.jpg", "original.jpeg", "original.png", "original.heic"] {
            let url = folderURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return imageFiles(in: folderURL)
            .filter { url in
                let fileName = url.lastPathComponent.lowercased()
                return !fileName.hasPrefix("hand-drawn")
                    && !fileName.hasPrefix("foreground-dog")
            }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
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
