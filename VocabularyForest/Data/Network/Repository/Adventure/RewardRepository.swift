//
//  RewardRepository.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.05.2026.
//


import Foundation
import DTO

enum RewardRepositoryError: Error {
    case decodingError
    case emptyTypeError
    case emptySourceError
    case emptyCategoryError
    case emptyLocalImageError
    case emptyChest
    case downloadImageError
    case emptyRemotePath
    case zipExtractionError
    case invalidArgument
}

protocol RewardRepositoryProtocol {
    func processAndGetLocalReward(from remoteReward: RemoteRewardModel) async throws -> LocalRewardModel
    func claimLocalReward(reward: LocalRewardModel) async throws
}

final class RewardRepository {
    
    private let offlineAssetManager: OfflineAssetManagerProtocol
    private let networkManager: APIServiceProtocol
    private let chestRepository: ChestRepositoryProtocol
    private let forestRepository: ForestDataManagerProtocol
    
    init(assetManager: OfflineAssetManagerProtocol, apiService: APIServiceProtocol, chestRepository: ChestRepositoryProtocol, forestManager: ForestDataManagerProtocol) {
        self.offlineAssetManager = assetManager
        self.networkManager = apiService
        self.chestRepository = chestRepository
        self.forestRepository = forestManager
    }
    
    static func posterName(id: String) -> String {
        "\(id)_poster"
    }
}

extension RewardRepository: RewardRepositoryProtocol {
    func claimLocalReward(reward: LocalRewardModel) async throws {
        switch reward.reward {
            case .standart(model: let model):
            switch model.imageSource {
            case .local:
                let rewardModel = ReadyRewardModel(id: model.id, category: model.category, rewardCount: reward.rewardCount, displayName: model.displayName, assetSource: RewardAssetReference(key: model.assetName, source: .appAssets), posterImage: model.posterImage)
                try forestRepository.claimReward(model: rewardModel, contextType: .background)
            case .remote:
                guard let remotePath = model.remotePath, let version = model.remoteAssetVersion else { throw RewardRepositoryError.emptyRemotePath }
                do {
                    try await downloadAndSaveImageIfNeeded(remotePath: remotePath, localKey: model.assetName, version: version)
                    let _ = try offlineAssetManager.isAssetReady(assetName: model.assetName)
                    let rewardModel = ReadyRewardModel(id: model.id, category: model.category, rewardCount: reward.rewardCount, displayName: model.displayName, assetSource: RewardAssetReference(key: model.assetName, source: .offlineStorage), posterImage: model.posterImage)
                    try forestRepository.claimReward(model: rewardModel, contextType: .background)
                }catch {
                    throw error
                }
            case .zip:
                guard let remotePath = model.remotePath, let version = model.remoteAssetVersion else { throw RewardRepositoryError.emptyRemotePath }
                do {
                    try await downloadAndSaveZipIfNeeded(remotePath: remotePath, localKey: model.assetName, version: version)
                    guard offlineAssetManager.isZipAssetReady(bundleId: model.assetName) else {
                        throw RewardRepositoryError.zipExtractionError
                    }
                    let rewardModel = ReadyRewardModel(id: model.id, category: model.category, rewardCount: reward.rewardCount, displayName: model.displayName, assetSource: RewardAssetReference(key: model.assetName, source: .offlineStorage), posterImage: model.posterImage)
                    try forestRepository.claimReward(model: rewardModel, contextType: .background)
                }catch {
                    throw error
                }
            }
            case .chest(model: let model):
            chestRepository.openChest(chestId: model.id)
        }
    }
    
    func processAndGetLocalReward(from remoteReward: RemoteRewardModel) async throws -> LocalRewardModel {
        
        var localReward: LocalRewardModel
        
        if let id = remoteReward.id, let type = remoteReward.type, let rewardCount = remoteReward.rewardCount, let displayName = remoteReward.displayName, let imageSource = remoteReward.imageSource, let assetName = remoteReward.assetName {
            
            guard let imageSource = ImageSource.convertImageSource(value: imageSource) else { throw RewardRepositoryError.emptySourceError }
            var localRewardType: LocalRewardType
            var posterImage: RewardAssetReference
            let posterName = RewardRepository.posterName(id: id)
            
            switch imageSource {
            case .local:
                guard let localImageName = remoteReward.localImageName else { throw RewardRepositoryError.emptyLocalImageError }
                posterImage = RewardAssetReference(key: localImageName, source: .appAssets)
            default:
                posterImage = RewardAssetReference(key: posterName, source: .offlineStorage)
            }
            
            switch type {
                case "standart":
                    guard let safeCategory = remoteReward.category, let category = QuestRewardModel.convertQuestReward(value: safeCategory) else { throw RewardRepositoryError.emptyCategoryError }
                    localRewardType = LocalRewardType.standart(
                        model: LocalQuestRewardModel(
                            id: id,
                            category: category,
                            displayName: displayName,
                            assetName: assetName,
                            imageSource: imageSource,
                            posterImage: posterImage,
                            remotePath: remoteReward.remotePath,
                            remoteAssetVersion: remoteReward.remoteAssetVersion,
                            textColorHex: remoteReward.textColorHex,
                            gradientHexes: remoteReward.gradientHexes
                        )
                    )
                case "chest":
                guard let chest = chestRepository.getLocalChest(chestId: id) else { throw RewardRepositoryError.emptyChest }
                localRewardType = LocalRewardType.chest(model: chest)
            default:
                throw RewardRepositoryError.emptyTypeError
            }
            localReward = LocalRewardModel(
                rewardCount: rewardCount,
                reward: localRewardType
            )
            return localReward
        } else {
            throw RewardRepositoryError.decodingError
        }
    }
}

private extension RewardRepository {
    
    func getReadyReward(localReward: LocalQuestRewardModel, count: Int) async throws -> ReadyRewardModel {
        switch localReward.imageSource {
        case .local:
            throw RewardRepositoryError.invalidArgument
        case .remote:
            guard let remotePath = localReward.remotePath, let remoteAssetVersion = localReward.remoteAssetVersion else { throw RewardRepositoryError.emptySourceError }
            
            try await downloadAndSaveImageIfNeeded(remotePath: remotePath, localKey: localReward.assetName, version: remoteAssetVersion)
            let model = ReadyRewardModel(id: localReward.id, category: localReward.category, rewardCount: count, displayName: localReward.displayName, assetSource: RewardAssetReference(key: localReward.assetName, source: .offlineStorage), posterImage: localReward.posterImage)
            return model
        case .zip:
            guard let remotePath = localReward.remotePath, let remoteAssetVersion = localReward.remoteAssetVersion else { throw RewardRepositoryError.emptySourceError }
            try await downloadAndSaveZipIfNeeded(remotePath: remotePath, localKey: localReward.assetName, version: remoteAssetVersion)
            let model = ReadyRewardModel(id: localReward.id, category: localReward.category, rewardCount: count, displayName: localReward.displayName, assetSource: RewardAssetReference(key: localReward.assetName, source: .offlineStorage), posterImage: localReward.posterImage)
            return model
        }
        
    }
    
    func downloadAndSaveZipIfNeeded(remotePath: String, localKey: String, version: Int) async throws {
        if offlineAssetManager.isZipAssetUpToDate(bundleId: localKey, expectedVersion: version) {
            return
        }
        
        let getZipModel = GetZipRequestModel(remotePath: remotePath)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            networkManager.fetchZip(values: getZipModel) { [weak self] result in
                guard let self else {
                    continuation.resume(throwing: RewardRepositoryError.invalidArgument)
                    return
                }
                
                switch result {
                case .success(let zipData):
                    do {
                        try self.offlineAssetManager.saveAndExtractZip(zipData: zipData)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func downloadAndSaveImageIfNeeded(remotePath: String, localKey: String, version: Int) async throws {
        if offlineAssetManager.isAssetUpToDate(imageName: localKey, expectedVersion: version) {
            return
        }
        
        let getImageModel = GetImageRequestModel(imagePath: remotePath)
        var networkError: Error?
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
                    networkError = saveResult.error ?? RewardRepositoryError.downloadImageError
                }
                
            case .failure(let error):
                networkError = error
            }
        }
        if let networkError {
            throw networkError
        }
        return
    }
}
