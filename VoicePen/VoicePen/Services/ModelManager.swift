import Foundation
import SwiftUI

@Observable
final class ModelManager {
    var downloadedModels: [String] = []
    var isDownloading = false
    var downloadProgress: Double = 0
    var currentDownloadModel: String?

    private let modelsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    init() {
        scanDownloadedModels()
    }

    func scanDownloadedModels() {
        downloadedModels = []
        let contents = try? FileManager.default.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        )
        for url in contents ?? [] {
            if url.hasDirectoryPath {
                downloadedModels.append(url.lastPathComponent)
            }
        }
    }

    func isModelDownloaded(_ model: String) -> Bool {
        return downloadedModels.contains(model)
    }

    func modelStorageSize(_ model: String) -> Int64 {
        let modelDir = modelsDirectory.appendingPathComponent(model)
        return directorySize(at: modelDir)
    }

    func totalStorageUsed() -> Int64 {
        return directorySize(at: modelsDirectory)
    }

    func deleteModel(_ model: String) throws {
        let modelDir = modelsDirectory.appendingPathComponent(model)
        try FileManager.default.removeItem(at: modelDir)
        downloadedModels.removeAll { $0 == model }
    }

    func recordingsStorageSize() -> Int64 {
        let recordingsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
        return directorySize(at: recordingsDir)
    }

    private func directorySize(at url: URL) -> Int64 {
        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: .skipsHiddenFiles
            )
        } catch {
            return 0
        }

        var total: Int64 = 0
        for itemURL in contents {
            let resourceValues = try? itemURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if resourceValues?.isDirectory == true {
                total += directorySize(at: itemURL)
            } else {
                total += Int64(resourceValues?.fileSize ?? 0)
            }
        }
        return total
    }

    func formatStorage(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
