//
//  RewardAssetHydrationService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.07.2026.
//

import Foundation

protocol RewardAssetHydrationServiceProtocol {
    /// Downloads any assets referenced by the restored forest that are missing on this
    /// device, using the rewards catalog from Remote Config. Failures are swallowed:
    /// missing assets are retried on the next restore/hydration attempt.
    func hydrateMissingAssets(for forest: SafeForestModel) async
}

final class RewardAssetHydrationService {
    
    private let assetDownloader: RewardAssetDownloaderProtocol
    private let remoteConfigRepository: RemoteConfigRepositoryProtocol
    
    init(
        assetDownloader: RewardAssetDownloaderProtocol,
        remoteConfigRepository: RemoteConfigRepositoryProtocol
    ) {
        self.assetDownloader = assetDownloader
        self.remoteConfigRepository = remoteConfigRepository
    }
}

extension RewardAssetHydrationService: RewardAssetHydrationServiceProtocol {
    
    func hydrateMissingAssets(for forest: SafeForestModel) async {
        let offlineEntities = offlineStoredEntities(in: forest)
        guard !offlineEntities.isEmpty else { return }
        
        guard let resolver = await fetchCatalogResolver() else { return }
        
        var processedAssetNames = Set<String>()
        for entity in offlineEntities {
            guard processedAssetNames.insert(entity.assetName).inserted else { continue }
            
            guard let catalogItem = resolver.catalogItem(rewardId: entity.rewardId, assetName: entity.assetName) else {
                continue
            }
            await hydrate(entity: entity, using: catalogItem)
        }
    }
}

private extension RewardAssetHydrationService {
    
    struct OfflineEntity {
        let assetName: String
        let rewardId: String?
        let poster: RewardAssetReference
    }
    
    func offlineStoredEntities(in forest: SafeForestModel) -> [OfflineEntity] {
        var entities: [OfflineEntity] = []
        for tree in forest.trees where tree.assetSource == .offlineStorage {
            entities.append(OfflineEntity(assetName: tree.assetName, rewardId: tree.rewardId, poster: tree.poster))
        }
        for animal in forest.animals where animal.assetSource == .offlineStorage {
            entities.append(OfflineEntity(assetName: animal.assetName, rewardId: animal.rewardId, poster: animal.poster))
        }
        for sculpture in forest.sculptures where sculpture.assetSource == .offlineStorage {
            entities.append(OfflineEntity(assetName: sculpture.assetName, rewardId: sculpture.rewardId, poster: sculpture.poster))
        }
        return entities
    }
    
    func fetchCatalogResolver() async -> RewardCatalogResolver? {
        do {
            let response = try await remoteConfigRepository.fetchRewardsCatalog()
            let items = response.model.items ?? []
            guard !items.isEmpty else { return nil }
            return RewardCatalogResolver(items: items)
        } catch {
            return nil
        }
    }
    
    func hydrate(entity: OfflineEntity, using catalogItem: RemoteRewardModel) async {
        guard let sourceString = catalogItem.imageSource,
              let imageSource = ImageSource.convertImageSource(value: sourceString),
              let remotePath = catalogItem.remotePath,
              let version = catalogItem.remoteAssetVersion else {
            return
        }
        
        do {
            switch imageSource {
            case .local:
                return
            case .remote:
                try await assetDownloader.downloadAndSaveImageIfNeeded(
                    remotePath: remotePath,
                    localKey: entity.assetName,
                    version: version
                )
            case .zip:
                try await assetDownloader.downloadAndSaveZipIfNeeded(
                    remotePath: remotePath,
                    localKey: entity.assetName,
                    version: version
                )
            }
            
            if entity.poster.source == .offlineStorage, let posterIconPath = catalogItem.posterIconPath {
                try await assetDownloader.downloadAndSaveImageIfNeeded(
                    remotePath: posterIconPath,
                    localKey: entity.poster.key,
                    version: version
                )
            }
        } catch {
            // Best effort: a failed download must not break the restore flow.
        }
    }
}
