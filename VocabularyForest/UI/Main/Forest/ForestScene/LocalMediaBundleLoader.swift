//
//  LocalMediaBundleLoader.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.05.2026.
//

import Foundation
import SpriteKit
import UIKit

enum ForestLocalAnimationKey: String {
    case idle
    case walk
    case jump
    case frames
}

enum LocalMediaBundleLoader {
    private static let manifestFileName = "manifest.json"

    static func textures(rootPath: String?, animationKey: ForestLocalAnimationKey) -> [SKTexture] {
        guard let bundle = loadBundle(rootPath: rootPath) else {
            return []
        }

        let animationPaths = resolveAnimationPaths(in: bundle.manifest, key: animationKey)
        return animationPaths.compactMap { texture(relativePath: $0, bundle: bundle) }
    }

    static func posterTexture(rootPath: String?) -> SKTexture? {
        guard let bundle = loadBundle(rootPath: rootPath) else {
            return nil
        }

        if let posterFrame = bundle.manifest.posterFrame,
           let texture = texture(relativePath: posterFrame, bundle: bundle) {
            return texture
        }

        if let firstAnimation = bundle.manifest.animations.values.first,
           let firstFrame = firstAnimation.first {
            return texture(relativePath: firstFrame, bundle: bundle)
        }

        return nil
    }
}

private extension LocalMediaBundleLoader {
    struct ManifestModel: Decodable {
        let bundleId: String?
        let version: String?
        let format: String?
        let posterFrame: String?
        let animations: [String: [String]]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
            version = try container.decodeIfPresent(String.self, forKey: .version)
            format = try container.decodeIfPresent(String.self, forKey: .format)
            posterFrame = try container.decodeIfPresent(String.self, forKey: .posterFrame)
            animations = try container.decodeIfPresent([String: [String]].self, forKey: .animations) ?? [:]
        }

        enum CodingKeys: String, CodingKey {
            case bundleId
            case version
            case format
            case posterFrame
            case animations
        }
    }

    struct LoadedBundle {
        let rootURL: URL
        let manifestURL: URL
        let manifest: ManifestModel
    }

    static func resolveAnimationPaths(in manifest: ManifestModel, key: ForestLocalAnimationKey) -> [String] {
        if let direct = manifest.animations[key.rawValue], !direct.isEmpty {
            return direct
        }

        if key == .frames, let idle = manifest.animations[ForestLocalAnimationKey.idle.rawValue] {
            return idle
        }

        return []
    }

    static func loadBundle(rootPath: String?) -> LoadedBundle? {
        guard let rootPath,
              !rootPath.isEmpty else {
            return nil
        }

        let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
        guard let manifestURL = locateManifest(in: rootURL),
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(ManifestModel.self, from: data) else {
            return nil
        }

        return LoadedBundle(rootURL: rootURL, manifestURL: manifestURL, manifest: manifest)
    }

    static func locateManifest(in rootURL: URL) -> URL? {
        let fileManager = FileManager.default
        let rootManifest = rootURL.appendingPathComponent(manifestFileName)
        if fileManager.fileExists(atPath: rootManifest.path) {
            return rootManifest
        }

        guard let entries = try? fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for entry in entries {
            let isDirectory = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            guard isDirectory else { continue }
            let nestedManifest = entry.appendingPathComponent(manifestFileName)
            if fileManager.fileExists(atPath: nestedManifest.path) {
                return nestedManifest
            }
        }

        return nil
    }

    static func texture(relativePath: String, bundle: LoadedBundle) -> SKTexture? {
        guard let resolvedPath = resolveFramePath(relativePath: relativePath, bundle: bundle),
              let image = UIImage(contentsOfFile: resolvedPath.path) else {
            return nil
        }

        return SKTexture(image: image)
    }

    static func resolveFramePath(relativePath: String, bundle: LoadedBundle) -> URL? {
        let trimmed = relativePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let fileManager = FileManager.default

        if trimmed.hasPrefix("/") {
            let absoluteURL = URL(fileURLWithPath: trimmed)
            if fileManager.fileExists(atPath: absoluteURL.path) {
                return absoluteURL
            }
            return nil
        }

        let fromRoot = bundle.rootURL.appendingPathComponent(trimmed)
        if fileManager.fileExists(atPath: fromRoot.path) {
            return fromRoot
        }

        let manifestFolder = bundle.manifestURL.deletingLastPathComponent()
        let fromManifestFolder = manifestFolder.appendingPathComponent(trimmed)
        if fileManager.fileExists(atPath: fromManifestFolder.path) {
            return fromManifestFolder
        }

        return nil
    }
}
