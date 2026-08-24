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

/// Download primitives shared with `RewardAssetHydrationService` so that assets
/// missing after a cloud restore can be re-downloaded with the same logic used at claim time.
protocol RewardAssetDownloaderProtocol {
    func downloadAndSaveImageIfNeeded(remotePath: String, localKey: String, version: Int) async throws
    func downloadAndSaveZipIfNeeded(remotePath: String, localKey: String, version: Int) async throws
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
    
    static func posterName(assetName: String) -> String {
        "\(assetName)_poster"
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
            do {
                let rewards = try await chestRepository.openChest(chestId: model.id)
                for reward in rewards {
                    try await claimLocalReward(reward: reward)
                }
            }catch {
                throw error
            }
        }
    }
    
    func processAndGetLocalReward(from remoteReward: RemoteRewardModel) async throws -> LocalRewardModel {
        
        var localReward: LocalRewardModel
        
        if let id = remoteReward.id, let type = remoteReward.type, let rewardCount = remoteReward.rewardCount, let displayName = remoteReward.displayName  {
            
            var localRewardType: LocalRewardType
            
            switch type {
                case "standart":
                    guard let safeCategory = remoteReward.category, let category = QuestRewardModel.convertQuestReward(value: safeCategory),let imageSource = remoteReward.imageSource, let assetName = remoteReward.assetName else { throw RewardRepositoryError.emptyCategoryError }
                    guard let imageSource = ImageSource.convertImageSource(value: imageSource) else
                    { throw RewardRepositoryError.emptySourceError
                    }
                    let posterImage = try await posterReference(for: remoteReward, imageSource: imageSource, assetName: assetName)

                    localRewardType = LocalRewardType.standart(
                        model: LocalQuestRewardModel(
                            id: id,
                            category: category,
                            tier: remoteReward.rewardTier,
                            displayName: displayName,
                            assetName: assetName,
                            imageSource: imageSource,
                            posterImage: posterImage,
                            remotePath: remoteReward.remotePath,
                            remoteAssetVersion: remoteReward.remoteAssetVersion,
                            textColorHex: remoteReward.textColorHex,
                            textStrokeColorHex: remoteReward.textStrokeColorHex,
                            gradientHexes: remoteReward.gradientHexes,
                            roadColorHex: remoteReward.roadColorHex,
                            cardGradientHexes: remoteReward.cardGradientHexes,
                            cardTextColorHex: remoteReward.cardTextColorHex
                        )
                    )
                case "chest":
                guard let chestID = remoteReward.chestId , let chest = chestRepository.getLocalChest(chestId: chestID) else {
                    throw RewardRepositoryError.emptyChest
                }
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
    func posterReference(
        for remoteReward: RemoteRewardModel,
        imageSource: ImageSource,
        assetName: String
    ) async throws -> RewardAssetReference {
        switch imageSource {
        case .local:
            guard let localImageName = remoteReward.localImageName else {
                throw RewardRepositoryError.emptyLocalImageError
            }
            return RewardAssetReference(key: localImageName, source: .appAssets)
            
        case .remote, .zip:
            let posterName = RewardRepository.posterName(assetName: assetName)
            guard let posterIconPath = remoteReward.posterIconPath,
                  let version = remoteReward.remoteAssetVersion else {
                return RewardAssetReference(key: posterName, source: .offlineStorage)
            }
            try await downloadAndSaveImageIfNeeded(
                remotePath: posterIconPath,
                localKey: posterName,
                version: version
            )
            return RewardAssetReference(key: posterName, source: .offlineStorage)
        }
    }
    
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
    
}

extension RewardRepository: RewardAssetDownloaderProtocol {
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
                        try self.offlineAssetManager.saveAndExtractZip(zipData: zipData, localKey: localKey, version: version)
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
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            networkManager.fetchImage(values: getImageModel) { [weak self] result in
                guard let self else {
                    continuation.resume(throwing: RewardRepositoryError.invalidArgument)
                    return
                }
                switch result {
                case .success(let imageData):
                    let saveResult = offlineAssetManager.saveImageToAssets(
                        data: imageData,
                        imageName: localKey,
                        version: version
                    )
                    if saveResult.status == .error {
                        continuation.resume(throwing: saveResult.error ?? RewardRepositoryError.downloadImageError)
                    } else {
                        continuation.resume()
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
