//
//  OfflineAssetManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.05.2026.
//

import Foundation
import SwiftUI

enum AssetManagerError: Error {
    case saveError
    case fetchError
    case emptyAsset
}

protocol OfflineAssetManagerProtocol {
    func saveImageToAssets(data: Data, imageName: String, version: Int) -> Resource<Bool>
    func loadImageFromAssets(imageName: String) -> Resource<UIImage>
    func fileExists(fileName: String) -> Bool
    func isAssetUpToDate(imageName: String, expectedVersion: Int) -> Bool
}

final class OfflineAssetManager {
    
    // MARK: - PROPERTIES
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    private let assetFolderName = "OfflineGameAssets"
    
    // MARK: - INIT
    
    init() {
        createAssetFolderIfNeeded()
    }
}

extension OfflineAssetManager: OfflineAssetManagerProtocol {
    
    func isAssetUpToDate(imageName: String, expectedVersion: Int) -> Bool {
        let filePath = getLocalFileURL(for: imageName)
        guard fileManager.fileExists(atPath: filePath.path) else { return false }
        let savedVersion = userDefaults.integer(forKey: "version_\(imageName)")
        return savedVersion >= expectedVersion
    }
    
    func fileExists(fileName: String) -> Bool {
        let filePath = getLocalFileURL(for: fileName)
        return fileManager.fileExists(atPath: filePath.path)
    }
    
    func saveImageToAssets(data: Data, imageName: String, version: Int) -> Resource<Bool> {
        let fileURL = getLocalFileURL(for: imageName)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return Resource.error(error: AssetManagerError.saveError)
        }
        userDefaults.set(version, forKey: "version_\(imageName)")
        return Resource.success(true)
    }
    
    func loadImageFromAssets(imageName: String) -> Resource<UIImage> {
        let fileURL = getLocalFileURL(for: imageName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return Resource.error(error: AssetManagerError.emptyAsset)
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return Resource.success(UIImage(data: data))
        } catch {
            return Resource.error(error: AssetManagerError.fetchError)
        }
    }
}

private extension OfflineAssetManager {
    func getAssetDirectory() -> URL {
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupportDirectory.appendingPathComponent(assetFolderName)
    }
    
    func createAssetFolderIfNeeded() {
        let folderURL = getAssetDirectory()
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
            }
        }
    }
    
    func getLocalFileURL(for imageName: String) -> URL {
        return getAssetDirectory().appendingPathComponent("\(imageName).png")
    }
}
