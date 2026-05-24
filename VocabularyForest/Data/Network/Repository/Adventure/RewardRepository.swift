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
}

protocol RewardRepositoryProtocol {
    func processAndGetLocalReward(from remoteReward: RemoteRewardModel) async -> Resource<LocalRewardModel>
}

final class RewardRepository {
    
    private let offlineAssetManager: OfflineAssetManagerProtocol
    private let networkManager: APIServiceProtocol
    private let chestRepository: ChestRepositoryProtocol
    
    init(assetManager: OfflineAssetManagerProtocol, apiService: APIServiceProtocol, chestRepository: ChestRepositoryProtocol) {
        self.offlineAssetManager = assetManager
        self.networkManager = apiService
        self.chestRepository = chestRepository
    }
}

extension RewardRepository: RewardRepositoryProtocol {
    func processAndGetLocalReward(from remoteReward: RemoteRewardModel) async -> Resource<LocalRewardModel> {
        
        var localReward: LocalRewardModel
        
        if let id = remoteReward.id, let type = remoteReward.type, let rewardCount = remoteReward.rewardCount, let displayName = remoteReward.displayName, let imageSource = remoteReward.imageSource {
            
            guard let imageSource = ImageSource.convertImageSource(value: imageSource) else { return Resource.error(error: RewardRepositoryError.emptySourceError) }
            var localRewardType: LocalRewardType
            var posterImage: RewardPosterInfo
            let posterName = posterName(id: id)
            
            switch imageSource {
            case .local:
                guard let localImageName = remoteReward.localImageName else { return Resource.error(error: RewardRepositoryError.emptyLocalImageError)}
                posterImage = RewardPosterInfo(key: localImageName, source: .appAssets)
            default:
                posterImage = RewardPosterInfo(key: posterName, source: .offlineStorage)
            }
            
            switch type {
                case "standart":
                    guard let safeCategory = remoteReward.category, let category = QuestRewardModel.convertQuestReward(value: safeCategory) else { return Resource.error(error: RewardRepositoryError.emptyCategoryError)}
                    localRewardType = LocalRewardType.standart(
                        model: LocalQuestRewardModel(
                            id: id,
                            category: category,
                            displayName: displayName,
                            imageSource: imageSource,
                            posterImage: posterImage,
                            remotePath: remoteReward.remotePath,
                            textColorHex: remoteReward.textColorHex,
                            gradientHexes: remoteReward.gradientHexes
                        )
                    )
                case "chest":
                guard let chest = chestRepository.getLocalChest(chestId: id) else { return Resource.error(error: RewardRepositoryError.emptyChest) }
                localRewardType = LocalRewardType.chest(model: chest)
            default:
                return Resource.error(error: RewardRepositoryError.emptyTypeError)
            }
            localReward = LocalRewardModel(
                rewardCount: rewardCount,
                reward: localRewardType
            )
            return Resource.success(localReward)
        } else {
            return Resource.error(error: RewardRepositoryError.decodingError)
        }
        
    }
}

private extension RewardRepository {
    func downloadAndSaveImageIfNeeded(remotePath: String, localKey: String, version: Int) async -> Bool {
        
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
    
    func posterName(id: String) -> String {
        "\(id)_poster"
    }
}
