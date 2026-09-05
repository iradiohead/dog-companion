import Foundation
import os

/// Persists generated portraits and foreground cutouts to an easy-to-find folder.
enum GeneratedImageArchive {
    static let appFolderName = "DogCompanion"
    static let folderName = "hand-drawn-portraits"

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.kejin.dogcompanion",
        category: "GeneratedImageArchive"
    )

    /// Override in tests to write into a temporary directory.
    static var rootDirectory: URL?

    /// Most recently written file (useful for debugging).
    private(set) static var lastSavedURL: URL?

    static func directoryURL() throws -> URL {
        if let rootDirectory {
            try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            return rootDirectory
        }

        let directory = defaultArchiveDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Mac Catalyst: `~/Library/.../DogCompanion/hand-drawn-portraits/` (see console log for full path)
    /// iPhone: `Documents/DogCompanion/hand-drawn-portraits/` (visible in Files app)
    static func defaultArchiveDirectory() -> URL {
        let base: URL
        #if targetEnvironment(macCatalyst)
        base = (try? FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
        #else
        base = (try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory
        #endif

        return base
            .appendingPathComponent(appFolderName, isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }

    @discardableResult
    static func savePortrait(_ data: Data, pose: CompanionPose = .sit) throws -> URL {
        try save(data, prefix: "hand-drawn-\(pose.rawValue)", kind: "手绘肖像")
    }

    @discardableResult
    static func saveForegroundCutout(_ data: Data, pose: CompanionPose = .sit) throws -> URL {
        try save(data, prefix: "foreground-dog-\(pose.rawValue)", kind: "前景抠图")
    }

    @discardableResult
    static func saveCutout(_ data: Data, pose: CompanionPose = .sit) throws -> URL {
        try saveForegroundCutout(data, pose: pose)
    }

    private static func save(_ data: Data, prefix: String, kind: String) throws -> URL {
        let directory = try directoryURL()
        let stamp = filenameTimestamp()
        let fileURL = directory.appendingPathComponent("\(prefix)-\(stamp).png")
        try data.write(to: fileURL, options: .atomic)
        lastSavedURL = fileURL
        logSaved(kind: kind, fileURL: fileURL, byteCount: data.count)
        return fileURL
    }

    private static func logSaved(kind: String, fileURL: URL, byteCount: Int) {
        let message = "DogCompanion [\(kind)] 已保存 (\(byteCount) bytes): \(fileURL.path)"
        logger.info("\(message)")
        print(message)
    }

    private static func filenameTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
    }
}
