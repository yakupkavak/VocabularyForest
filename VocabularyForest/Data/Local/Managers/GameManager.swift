//
//  GameManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.04.2026.
//

import Foundation

protocol GameManagerProtocol: AnyObject {
    func refreshEconomyConfig() async -> Resource<GameEconomyConfigModel>
    func currentEconomyConfig() -> GameEconomyConfigModel?
    func currentChestRewardsConfig() -> ChestRewardsConfigModel?
}

final class GameManager {
    private let remoteConfigRepository: RemoteConfigRepositoryProtocol
    private var cachedEconomyConfig: GameEconomyConfigModel?
    private var cachedChestRewardsConfig: ChestRewardsConfigModel?
    private static let cacheLock = NSLock()
    private static var sharedEconomyConfig: GameEconomyConfigModel?
    private static var sharedChestRewardsConfig: ChestRewardsConfigModel?

    init(remoteConfigRepository: RemoteConfigRepositoryProtocol) {
        self.remoteConfigRepository = remoteConfigRepository
    }
    
    static func snapshotEconomyConfig() -> GameEconomyConfigModel? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return sharedEconomyConfig
    }

    static func snapshotChestRewardsConfig() -> ChestRewardsConfigModel? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return sharedChestRewardsConfig
    }
    
    private static func setSnapshotEconomyConfig(_ config: GameEconomyConfigModel) {
        cacheLock.lock()
        sharedEconomyConfig = config
        cacheLock.unlock()
    }

    private static func setSnapshotChestRewardsConfig(_ config: ChestRewardsConfigModel) {
        cacheLock.lock()
        sharedChestRewardsConfig = config
        cacheLock.unlock()
    }
}

extension GameManager: GameManagerProtocol {
    func refreshEconomyConfig() async -> Resource<GameEconomyConfigModel> {
        let result = await remoteConfigRepository.fetchGameEconomyConfig()
        if result.status == .success, let config = result.data {
            cachedEconomyConfig = config
            Self.setSnapshotEconomyConfig(config)
        }

        let chestConfigResult = await remoteConfigRepository.fetchChestRewardsConfig()
        if chestConfigResult.status == .success, let chestConfig = chestConfigResult.data {
            cachedChestRewardsConfig = chestConfig
            Self.setSnapshotChestRewardsConfig(chestConfig)
        } else if let cachedChestConfig = remoteConfigRepository.cachedChestRewardsConfig() {
            cachedChestRewardsConfig = cachedChestConfig
            Self.setSnapshotChestRewardsConfig(cachedChestConfig)
        }

        return result
    }
    
    func currentEconomyConfig() -> GameEconomyConfigModel? {
        cachedEconomyConfig ?? Self.snapshotEconomyConfig()
    }

    func currentChestRewardsConfig() -> ChestRewardsConfigModel? {
        cachedChestRewardsConfig ?? Self.snapshotChestRewardsConfig()
    }
}
