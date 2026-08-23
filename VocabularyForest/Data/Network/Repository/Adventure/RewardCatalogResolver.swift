//
//  RewardCatalogResolver.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.07.2026.
//

import Foundation

/// Resolves asset source information for restored forest entities using the
/// centralized rewards catalog (`rewards_config` on Remote Config).
struct RewardCatalogResolver {
    
    struct ResolvedAsset {
        let assetSource: ImageSourceType
        let poster: RewardAssetReference
    }
    
    private let itemsById: [String: RemoteRewardModel]
    private let itemsByAssetName: [String: RemoteRewardModel]
    
    init(items: [RemoteRewardModel]) {
        var byId: [String: RemoteRewardModel] = [:]
        var byAssetName: [String: RemoteRewardModel] = [:]
        for item in items {
            if let id = item.id, byId[id] == nil {
                byId[id] = item
            }
            if let assetName = item.assetName, byAssetName[assetName] == nil {
                byAssetName[assetName] = item
            }
        }
        self.itemsById = byId
        self.itemsByAssetName = byAssetName
    }
    
    /// Finds the catalog entry for a restored entity. Older cloud records may not
    /// contain a rewardId; in that case we fall back to matching by assetName.
    func catalogItem(rewardId: String?, assetName: String) -> RemoteRewardModel? {
        if let rewardId, let item = itemsById[rewardId] {
            return item
        }
        return itemsByAssetName[assetName]
    }
    
    /// Resolves where the entity's main asset and poster live. When the reward is
    /// unknown to the catalog we assume it ships within the app bundle.
    func resolveAsset(rewardId: String?, assetName: String) -> ResolvedAsset {
        guard let item = catalogItem(rewardId: rewardId, assetName: assetName),
              let sourceString = item.imageSource,
              let imageSource = ImageSource.convertImageSource(value: sourceString) else {
            return ResolvedAsset(
                assetSource: .appAssets,
                poster: RewardAssetReference(key: assetName, source: .appAssets)
            )
        }
        
        switch imageSource {
        case .local:
            return ResolvedAsset(
                assetSource: .appAssets,
                poster: RewardAssetReference(key: item.localImageName ?? assetName, source: .appAssets)
            )
        case .remote, .zip:
            return ResolvedAsset(
                assetSource: .offlineStorage,
                poster: RewardAssetReference(
                    key: RewardRepository.posterName(assetName: assetName),
                    source: .offlineStorage
                )
            )
        }
    }
}
