//
//  GameManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.04.2026.
//

import Foundation

protocol GameManagerProtocol: AnyObject {
    func applyEconomyConfig(_ config: GameEconomyConfigModel)
    func currentEconomyConfig() -> GameEconomyConfigModel?
}

final class GameManager {
    private var cachedEconomyConfig: GameEconomyConfigModel?
    private static let cacheLock = NSLock()
    private static var sharedEconomyConfig: GameEconomyConfigModel?
    
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
    func applyEconomyConfig(_ config: GameEconomyConfigModel) {
        cachedEconomyConfig = config
        Self.setSnapshotEconomyConfig(config)
    }
    
    func currentEconomyConfig() -> GameEconomyConfigModel? {
        cachedEconomyConfig ?? Self.snapshotEconomyConfig()
    }
}
