//
//  ForestInitializerService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import Foundation
import CoreData

enum ForestInitError: Error {
    case playerCreation
    case forestCreation
    case alreadyCreated
}

protocol ForestInitializerServiceProtocol {
    func initializeNewGame() async -> Resource<Bool>
    func resetLocalGame() async -> Resource<Bool>
}

// MARK: - CONSTANTS

private extension ForestInitializerService {
    enum Constants {
        /// Historical key (typo included) already persisted on user devices; must not be renamed.
        static let forestInitializedKey = "forestInitalized"
    }
}

class ForestInitializerService: ForestInitializerServiceProtocol {
    private let forestManager: ForestDataManagerProtocol
    private let playerManager: PlayerDataManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol

    init(
        forestManager: ForestDataManagerProtocol,
        playerManager: PlayerDataManagerProtocol,
        coreData: CoreDataManagerProtocol,
    ) {
        self.forestManager = forestManager
        self.playerManager = playerManager
        self.coreDataManager = coreData
    }
    
    /// Post-account-deletion reset: wipes the local game state and immediately rebuilds a
    /// fresh empty forest, because ForestUI does not re-run initialization on entry.
    /// Clearing the first-reward flag makes the starter reward screen show again.
    func resetLocalGame() async -> Resource<Bool> {
        coreDataManager.deleteForestData(contextType: .background)
        await MainActor.run {
            UserDefaults.standard.set(false, forKey: Constants.forestInitializedKey)
            UserDefaults.standard.set(false, forKey: AppStorageNames.userClaimedFirtReward.rawValue)
        }
        return await initializeNewGame()
    }

    func initializeNewGame() async -> Resource<Bool> {
        let forestInitalized = UserDefaults.standard.bool(forKey: Constants.forestInitializedKey)
        
        if !forestInitalized {
            let playerResult = playerManager.createInitialPlayer(contextType: .background)
            guard playerResult.data != nil else {
                return Resource.error(error: ForestInitError.playerCreation)
            }
            let forestResult = forestManager.createForest(
                contextType: .background
            )
            guard let forest = forestResult.data else {
                return Resource.error(error: ForestInitError.playerCreation)
            }
            _ = playerManager.bindForest(contextType: .background, forest: forest)
            
            coreDataManager.save(type: .background)
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: Constants.forestInitializedKey)
            }
            return Resource.success(true)
        }
        return Resource.success(true)
    }
}
