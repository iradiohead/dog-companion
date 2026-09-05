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

    struct FolderContents {
        let dogName: String
        let folderURL: URL
        let imageFiles: [URL]

        var handDrawnURL: URL? {
            ResourceDogCatalog.latestPrefixedFile(in: imageFiles, prefix: "hand-drawn")
        }

        var foregroundURL: URL? {
            ResourceDogCatalog.latestPrefixedFile(in: imageFiles, prefix: "foreground-dog")
        }

        var originalURL: URL? {
            imageFiles
                .filter { !ResourceDogCatalog.isGeneratedAsset(fileName: $0.lastPathComponent) }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
                .first
        }

        var previewURL: URL? {
            handDrawnURL ?? originalURL ?? foregroundURL
        }
    }

    var bundle: Bundle = .main
    var resourceRootOverride: URL?

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

    func folderContents(for dogName: String) throws -> FolderContents {
        let folderURL = try folderURL(for: dogName)
        return FolderContents(
            dogName: dogName,
            folderURL: folderURL,
            imageFiles: imageFiles(in: folderURL)
        )
    }

    func previewImageURL(for dogName: String) -> URL? {
        try? folderContents(for: dogName).previewURL
    }

    fileprivate static func latestPrefixedFile(in files: [URL], prefix: String) -> URL? {
        files
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
    }

    fileprivate static func isGeneratedAsset(fileName: String) -> Bool {
        let lower = fileName.lowercased()
        return lower.hasPrefix("hand-drawn") || lower.hasPrefix("foreground-dog")
    }

    private func resourceRootURL() throws -> URL {
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

    private func folderURL(for dogName: String) throws -> URL {
        let url = try resourceRootURL().appendingPathComponent(dogName, isDirectory: true)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ResourceDogError.dogNotFound(dogName)
        }
        return url
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
