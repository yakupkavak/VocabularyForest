//
//  ChestVisualStorage.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

import Foundation
import CryptoKit
import DTO

protocol ChestVisualStorageProtocol: AnyObject {
    func syncVisualImages(_ visuals: [ChestVisualModel]) async
    func localImagePath(for remotePath: String) -> String?
}

final class ChestVisualStorage: ChestVisualStorageProtocol {
    private enum StorageConstants {
        static let folderName = "ChestVisuals"
    }

    private let apiService: APIServiceProtocol
    private let fileManager: FileManager

    init(
        apiService: APIServiceProtocol = APIService(),
        fileManager: FileManager = .default
    ) {
        self.apiService = apiService
        self.fileManager = fileManager
    }

    func syncVisualImages(_ visuals: [ChestVisualModel]) async {
        let remotePaths = Set(
            visuals.flatMap { [$0.closedImagePath, $0.openImagePath] }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )

        guard !remotePaths.isEmpty else {
            removeAllStoredImages()
            return
        }

        removeUnusedImages(keeping: remotePaths)

        for path in remotePaths {
            guard localImagePath(for: path) == nil else {
                continue
            }

            do {
                let data = try await downloadImage(path: path)
                try persistImageData(data, for: path)
            } catch {
                continue
            }
        }
    }

    func localImagePath(for remotePath: String) -> String? {
        let normalized = remotePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let fileURL = fileURLForRemotePath(normalized)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL.path : nil
    }
}

private extension ChestVisualStorage {
    func downloadImage(path: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            apiService.fetchImage(values: GetImageRequestModel(imagePath: path)) { result in
                continuation.resume(with: result)
            }
        }
    }

    func persistImageData(_ data: Data, for remotePath: String) throws {
        let folderURL = ensureStorageFolder()
        let fileURL = folderURL.appendingPathComponent(fileName(for: remotePath))
        try data.write(to: fileURL, options: .atomic)
    }

    func removeUnusedImages(keeping remotePaths: Set<String>) {
        let keepFileNames = Set(remotePaths.map { fileName(for: $0) })
        let folderURL = storageFolderURL

        guard let files = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for file in files where !keepFileNames.contains(file.lastPathComponent) {
            try? fileManager.removeItem(at: file)
        }
    }

    func removeAllStoredImages() {
        try? fileManager.removeItem(at: storageFolderURL)
    }

    func ensureStorageFolder() -> URL {
        let folderURL = storageFolderURL
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }

    func fileURLForRemotePath(_ remotePath: String) -> URL {
        storageFolderURL.appendingPathComponent(fileName(for: remotePath))
    }

    var storageFolderURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return documents.appendingPathComponent(StorageConstants.folderName, isDirectory: true)
    }

    func fileName(for remotePath: String) -> String {
        let normalized = remotePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastSegment = normalized.split(separator: "/").last.map(String.init) ?? "image.png"
        let digest = SHA256.hash(data: Data(normalized.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        return "\(digest)_\(lastSegment)"
    }
}
