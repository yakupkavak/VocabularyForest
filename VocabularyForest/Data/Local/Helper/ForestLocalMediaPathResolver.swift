//
//  ForestLocalMediaPathResolver.swift
//  VocabularyForest
//
//  Created by Codex on 3.05.2026.
//

import Foundation

enum ForestLocalMediaPathResolver {
    private static let mediaRootFolder = "ForestMediaBundles"
    private static let manifestFileName = "manifest.json"

    static func resolvePath(for assetName: String) -> String? {
        let trimmedAssetName = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAssetName.isEmpty,
              let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let rootFolder = documentURL.appendingPathComponent(mediaRootFolder, isDirectory: true)
        let folderCandidates = candidateFolders(for: trimmedAssetName, rootFolder: rootFolder)

        for folderURL in folderCandidates {
            if let resolved = resolveManifestContainer(in: folderURL) {
                return resolved.path
            }
        }

        return nil
    }
}

private extension ForestLocalMediaPathResolver {
    static func candidateFolders(for assetName: String, rootFolder: URL) -> [URL] {
        var urls: [URL] = [
            rootFolder.appendingPathComponent(assetName, isDirectory: true),
            rootFolder.appendingPathComponent(assetName.lowercased(), isDirectory: true),
            rootFolder.appendingPathComponent(assetName.uppercased(), isDirectory: true)
        ]

        if let dynamicMatch = searchCaseInsensitiveFolderMatch(for: assetName, rootFolder: rootFolder) {
            urls.append(dynamicMatch)
        }

        return Array(Set(urls))
    }

    static func searchCaseInsensitiveFolderMatch(for assetName: String, rootFolder: URL) -> URL? {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: rootFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        return entries.first { entry in
            (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true &&
            entry.lastPathComponent.lowercased() == assetName.lowercased()
        }
    }

    static func resolveManifestContainer(in folderURL: URL) -> URL? {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: folderURL.path) else {
            return nil
        }

        let directManifest = folderURL.appendingPathComponent(manifestFileName)
        if fileManager.fileExists(atPath: directManifest.path) {
            return folderURL
        }

        guard let entries = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        return entries.first { childURL in
            let isDirectory = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            guard isDirectory else { return false }
            let manifest = childURL.appendingPathComponent(manifestFileName)
            return fileManager.fileExists(atPath: manifest.path)
        }
    }
}
