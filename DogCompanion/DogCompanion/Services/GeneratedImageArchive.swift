import Foundation

/// Persists hand-drawn portraits returned by DashScope into Application Support.
enum GeneratedImageArchive {
    static let folderName = "hand-drawn-portraits"

    /// Override in tests to write into a temporary directory.
    static var rootDirectory: URL?

    static func directoryURL() throws -> URL {
        if let rootDirectory {
            try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            return rootDirectory
        }
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = appSupport
            .appendingPathComponent("DogCompanion", isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @discardableResult
    static func savePortrait(_ data: Data, pose: CompanionPose = .sit) throws -> URL {
        try save(data, prefix: "hand-drawn-\(pose.rawValue)")
    }

    @discardableResult
    static func saveCutout(_ data: Data, pose: CompanionPose = .sit) throws -> URL {
        try save(data, prefix: "cutout-\(pose.rawValue)")
    }

    private static func save(_ data: Data, prefix: String) throws -> URL {
        let directory = try directoryURL()
        let stamp = filenameTimestamp()
        let fileURL = directory.appendingPathComponent("\(prefix)-\(stamp).png")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func filenameTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
    }
}
