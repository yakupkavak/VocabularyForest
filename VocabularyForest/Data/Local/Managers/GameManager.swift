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
}

final class GameManager {
    private let remoteConfigRepository: RemoteConfigRepositoryProtocol
    private var cachedEconomyConfig: GameEconomyConfigModel?
    private static let cacheLock = NSLock()
    private static var sharedEconomyConfig: GameEconomyConfigModel?

    init(remoteConfigRepository: RemoteConfigRepositoryProtocol) {
        self.remoteConfigRepository = remoteConfigRepository
    }
    
    static func snapshotEconomyConfig() -> GameEconomyConfigModel? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return sharedEconomyConfig
    }
    
    private static func setSnapshotEconomyConfig(_ config: GameEconomyConfigModel) {
        cacheLock.lock()
        sharedEconomyConfig = config
        cacheLock.unlock()
    }
}

extension GameManager: GameManagerProtocol {
    func refreshEconomyConfig() async -> Resource<GameEconomyConfigModel> {
        /* // TODO: - BURAYA BAKILCAK.
        let result = await remoteConfigRepository.fetchGameEconomyConfig()
        if result.status == .success, let config = result.data {
            cachedEconomyConfig = config
            Self.setSnapshotEconomyConfig(config)
        }
        return result
         */
        return .error(error: nil)
    }
    
    func currentEconomyConfig() -> GameEconomyConfigModel? {
        cachedEconomyConfig ?? Self.snapshotEconomyConfig()
    }
}
