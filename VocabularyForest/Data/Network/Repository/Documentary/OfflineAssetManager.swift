//
//  OfflineAssetManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.05.2026.
//

import Foundation
import SwiftUI
import ZIPFoundation
import DTO

enum AssetManagerError: Error {
    case saveError
    case fetchError
    case emptyAsset
    case zipExtractionError
}

protocol OfflineAssetManagerProtocol {
    func saveImageToAssets(data: Data, imageName: String, version: Int) -> Resource<Bool>
    func saveAndExtractZip(zipData: Data) throws
    func loadImageFromAssets(imageName: String) throws -> UIImage
    func isAssetReady(assetName: String) throws -> Bool
    func fileExists(fileName: String) -> Bool
    func isAssetUpToDate(imageName: String, expectedVersion: Int) -> Bool
    func isZipAssetReady(bundleId: String) -> Bool
    func isZipAssetUpToDate(bundleId: String, expectedVersion: Int) -> Bool
}

final class OfflineAssetManager {
    
    // MARK: - PROPERTIES
    
    private let fileManager = FileManager.default
    private let userDefaults: UserDefaults
    private let baseDirectoryURL: URL
    
    // MARK: - INIT
    
    init(directoryURL: URL? = nil, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let directoryURL = directoryURL {
            self.baseDirectoryURL = directoryURL
        } else {
            let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectoryURL = appSupportDirectory.appendingPathComponent("OfflineGameAssets")
        }
        createAssetFolderIfNeeded()
    }
}

extension OfflineAssetManager: OfflineAssetManagerProtocol {
    
    func isZipAssetReady(bundleId: String) -> Bool {
        let folderURL = getAssetDirectory().appendingPathComponent(bundleId)
        return fileManager.fileExists(atPath: folderURL.path)
    }
        
    func isZipAssetUpToDate(bundleId: String, expectedVersion: Int) -> Bool {
        guard isZipAssetReady(bundleId: bundleId) else { return false }
        let savedVersion = userDefaults.integer(forKey: "version_\(bundleId)")
        return savedVersion >= expectedVersion
    }
    
    func saveAndExtractZip(zipData: Data) throws {
        let baseAssetDirectory = getAssetDirectory()
        let tempProcessFolderURL = baseAssetDirectory.appendingPathComponent("Temp_\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempProcessFolderURL, withIntermediateDirectories: true, attributes: nil)
        let tempZipURL = tempProcessFolderURL.appendingPathComponent("downloaded.zip")
        do {
            try zipData.write(to: tempZipURL, options: .atomic)
            try fileManager.unzipItem(at: tempZipURL, to: tempProcessFolderURL)
            try fileManager.removeItem(at: tempZipURL)
            let contents = try fileManager.contentsOfDirectory(atPath: tempProcessFolderURL.path)
            guard let bundleFolderName = contents.first(where: { !$0.hasPrefix(".") && !$0.hasPrefix("__") }) else {
                throw AssetManagerError.zipExtractionError
            }
            let extractedBundleURL = tempProcessFolderURL.appendingPathComponent(bundleFolderName)
            
            let manifestURL = extractedBundleURL.appendingPathComponent("manifest.json")
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(ManifestModel.self, from: manifestData)
            let finalDestinationURL = baseAssetDirectory.appendingPathComponent(bundleFolderName)
            
            if fileManager.fileExists(atPath: finalDestinationURL.path) {
                try fileManager.removeItem(at: finalDestinationURL)
            }
            try fileManager.moveItem(at: extractedBundleURL, to: finalDestinationURL)
            userDefaults.set(manifest.version, forKey: "version_\(manifest.bundleId)")
            try fileManager.removeItem(at: tempProcessFolderURL)
        } catch {
            try? fileManager.removeItem(at: tempProcessFolderURL)
            throw error
        }
    }
    
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
    
    func loadImageFromAssets(imageName: String) throws -> UIImage {
        let fileURL = getLocalFileURL(for: imageName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw AssetManagerError.emptyAsset
        }
        do {
            let data = try Data(contentsOf: fileURL)
            guard let image = UIImage(data: data) else { throw AssetManagerError.fetchError }
            return image
        } catch {
            throw AssetManagerError.fetchError
        }
    }
    
    func isAssetReady(assetName: String) throws -> Bool {
        let fileURL = getLocalFileURL(for: assetName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw AssetManagerError.emptyAsset
        }
        do {
            let data = try Data(contentsOf: fileURL)
            guard let image = UIImage(data: data) else { throw AssetManagerError.fetchError }
            return true
        } catch {
            throw AssetManagerError.fetchError
        }
    }
}

private extension OfflineAssetManager {
    func getAssetDirectory() -> URL {
        baseDirectoryURL
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
