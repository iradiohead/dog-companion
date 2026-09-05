import Foundation

/// Persists per-dog generated assets so re-selecting a bundle dog does not re-call the API.
enum ResourceDogAssetCache {
    static let appFolderName = "DogCompanion"
    static let folderName = "resource-cache"

    /// Override in tests to write into a temporary directory.
    static var rootDirectory: URL?

    static func portraitURL(for dogName: String, pose: CompanionPose = .sit) -> URL? {
        let url = fileURL(for: dogName, prefix: "hand-drawn", pose: pose)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    static func cutoutURL(for dogName: String, pose: CompanionPose = .sit) -> URL? {
        let url = fileURL(for: dogName, prefix: "foreground-dog", pose: pose)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    static func portraitData(for dogName: String, pose: CompanionPose = .sit) -> Data? {
        guard let url = portraitURL(for: dogName, pose: pose) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func cutoutData(for dogName: String, pose: CompanionPose = .sit) -> Data? {
        guard let url = cutoutURL(for: dogName, pose: pose) else { return nil }
        return try? Data(contentsOf: url)
    }

    @discardableResult
    static func savePortrait(_ data: Data, for dogName: String, pose: CompanionPose = .sit) throws -> URL {
        try save(data, for: dogName, prefix: "hand-drawn", pose: pose)
    }

    @discardableResult
    static func saveCutout(_ data: Data, for dogName: String, pose: CompanionPose = .sit) throws -> URL {
        try save(data, for: dogName, prefix: "foreground-dog", pose: pose)
    }

    private static func save(
        _ data: Data,
        for dogName: String,
        prefix: String,
        pose: CompanionPose
    ) throws -> URL {
        let directory = try dogDirectory(for: dogName)
        let fileURL = directory.appendingPathComponent("\(prefix)-\(pose.rawValue).png")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func fileURL(for dogName: String, prefix: String, pose: CompanionPose) -> URL {
        let directory = (try? dogDirectory(for: dogName))
            ?? cacheRootURL().appendingPathComponent(dogName, isDirectory: true)
        return directory.appendingPathComponent("\(prefix)-\(pose.rawValue).png")
    }

    private static func dogDirectory(for dogName: String) throws -> URL {
        let directory = cacheRootURL().appendingPathComponent(dogName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func cacheRootURL() -> URL {
        if let rootDirectory {
            return rootDirectory
        }

        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory

        return base
            .appendingPathComponent(appFolderName, isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }
}
