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
    case invalidChestId
    case chestListEmpty
}

protocol ChestRepositoryProtocol {
    func getLocalChest(chestId: String) -> LocalChestModel?
    func processAndSaveChests(from remoteChests: [RemoteChestModel]) async -> Resource<Bool>
    func openChest(chestId: String) async throws -> [LocalRewardModel]
}

final class ChestRepository {
    
    private let offlineAssetManager: OfflineAssetManagerProtocol
    private let networkManager: APIServiceProtocol
    private var localChestModels: [LocalChestModel]?
    private var chestEconomy: [String: RemoteChestEconomy] = [:]
    
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
    
    func openChest(chestId: String) async throws -> [LocalRewardModel] {
        guard let localChestModels else { throw ChestRepositoryError.chestListEmpty }
        guard let chest = localChestModels.first(where: { model in
            model.id == chestId
        }) else { throw ChestRepositoryError.invalidChestId }
        let economy = chestEconomy[chest.id]
        var rewards: [LocalRewardModel] = []
        do {
            if let guaranteed = economy?.guaranteedDrops {
                for guarantee in guaranteed {
                    guard let reward = guarantee.reward else { throw ChestRepositoryError.decodingError }
                    let rewardCount = Int.random(in: (guarantee.minAmount ?? 1)...(guarantee.maxAmount ?? 1))
                    let localReward = try await processAndGetLocalReward(from: reward, rewardCount: rewardCount)
                    rewards.append(localReward)
                }
            }
            if let randomDrops = economy?.randomDrops, !randomDrops.isEmpty {
                let totalChance = randomDrops.compactMap { $0.dropChance }.reduce(0, +)
                if totalChance > 0 {
                    let randomRoll = Int.random(in: 1...totalChance)
                    var currentWeight = 0
                    for drop in randomDrops {
                        if let chance = drop.dropChance {
                            currentWeight += chance
                            if randomRoll <= currentWeight {
                                guard let reward = drop.reward else { throw ChestRepositoryError.decodingError }
                                let rewardCount = Int.random(in: (drop.minAmount ?? 1)...(drop.maxAmount ?? 1))
                                let localReward = try await processAndGetLocalReward(from: reward, rewardCount: rewardCount)
                                rewards.append(localReward)
                                break
                            }
                        }
                    }
                }
            }
        }catch {
            throw error
        }
        if rewards.isEmpty {
            throw ChestRepositoryError.decodingError
        }else {
            return rewards
        }
    }
        
    func processAndSaveChests(from remoteChests: [RemoteChestModel]) async -> Resource<Bool> {
        var localChests: [LocalChestModel] = []
        
        for remoteChest in remoteChests {
            if let id = remoteChest.id, let version = remoteChest.version, let chestName = remoteChest.chestName, let version = remoteChest.version, let visuals = remoteChest.visuals, let economy = remoteChest.economy, let closedImagePath = visuals.closedImagePath, let openImagePath = visuals.openImagePath {
                chestEconomy[id] = economy
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
                        closeLocalImagePath: RewardAssetReference(key: closedChestKey, source: .offlineStorage),
                        openLocalImagePath: RewardAssetReference(key: openChestKey, source: .offlineStorage),
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

private extension ChestRepository {
    private func processAndGetLocalReward(from remoteReward: RemoteRewardModel, rewardCount: Int) async throws -> LocalRewardModel {
        var localReward: LocalRewardModel
        
        if let id = remoteReward.id, let type = remoteReward.type, let displayName = remoteReward.displayName, let imageSource = remoteReward.imageSource, let assetName = remoteReward.assetName {
            
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
                            textStrokeColorHex: remoteReward.textStrokeColorHex,
                            gradientHexes: remoteReward.gradientHexes
                        )
                    )
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
