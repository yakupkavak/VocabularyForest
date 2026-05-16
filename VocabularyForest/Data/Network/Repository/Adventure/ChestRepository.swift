//
//  ChestRepository.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.05.2026.
//

import Foundation
import DTO

enum ChestRepositoryError: Error {
    case decodingError
    case downloadImageError
}

protocol ChestRepositoryProtocol {
    func getLocalChest(chestId: String) -> LocalChestModel?
    func processAndSaveChests(from remoteChests: [RemoteChestModel]) async -> Resource<Bool>
}

final class ChestRepository {
    
    private let offlineAssetManager: OfflineAssetManagerProtocol
    private let networkManager: APIServiceProtocol
    private var localChestModels: [LocalChestModel]?
    
    init(assetManager: OfflineAssetManagerProtocol, apiService: APIServiceProtocol) {
        self.offlineAssetManager = assetManager
        self.networkManager = apiService
    }
    
    // MARK: - Private Downloader TODO: - static yapılacak
    
    private func downloadAndSaveImageIfNeeded(remotePath: String, localKey: String, version: Int) async -> Bool {
        
        if offlineAssetManager.isAssetUpToDate(imageName: localKey, expectedVersion: version) {
            return true
        }
        
        let getImageModel = GetImageRequestModel(imagePath: remotePath)
        networkManager.fetchImage(values: getImageModel) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let imageData):
                let saveResult = offlineAssetManager.saveImageToAssets(
                    data: imageData,
                    imageName: localKey,
                    version: version
                )
                if saveResult.status == .error {
                    print(saveResult.error ?? "Save error")
                }
                
            case .failure(let error):
                print(error)
            }
        }
        return true
    }
}

extension ChestRepository: ChestRepositoryProtocol {
    func getLocalChest(chestId: String) -> LocalChestModel? {
        guard let localChestModels else { return nil }
        return localChestModels.first { $0.id == chestId }
    }
        
    func processAndSaveChests(from remoteChests: [RemoteChestModel]) async -> Resource<Bool> {
        var localChests: [LocalChestModel] = []
        
        for remoteChest in remoteChests {
            if let id = remoteChest.id, let version = remoteChest.version, let chestName = remoteChest.chestName, let version = remoteChest.version, let visuals = remoteChest.visuals, let economy = remoteChest.economy, let closedImagePath = visuals.closedImagePath, let openImagePath = visuals.openImagePath {
                
                let closedChestKey = "\(id)_closed"
                let openChestKey = "\(id)_open"
                
                async let closedSuccess = downloadAndSaveImageIfNeeded(remotePath: closedImagePath, localKey: closedChestKey, version: version)
                async let openSuccess = downloadAndSaveImageIfNeeded(remotePath: openImagePath, localKey: openChestKey, version: version)
                
                let (isClosedSaved, isOpenSaved) = await (closedSuccess, openSuccess)
                
                if isClosedSaved && isOpenSaved {
                    let localChest = LocalChestModel(
                        id: id,
                        version: version,
                        displayName: chestName,
                        closeLocalImagePath: closedChestKey,
                        openLocalImagePath: openChestKey,
                        textHexColor: remoteChest.textHexColor,
                        backgroundGradientColors: remoteChest.gradientHexBackgroundColors
                    )
                    localChests.append(localChest)
                }else {
                    return Resource.error(error: ChestRepositoryError.downloadImageError)
                }
            }else {
                return Resource.error(error: ChestRepositoryError.decodingError)
            }
        }
        localChestModels = localChests
        return Resource.success(true)
    }
}
