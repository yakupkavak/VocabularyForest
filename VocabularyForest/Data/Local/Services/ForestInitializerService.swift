//
//  ForestInitializerService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import Foundation

enum ForestInitError: Error {
    case playerCreation
    case forestCreation
    case alreadyCreated
}

protocol ForestInitializerServiceProtocol {
    func initializeNewGame() async -> Resource<Bool>
}

class ForestInitializerService: ForestInitializerServiceProtocol {
    private let forestManager: ForestDataManagerProtocol
    private let playerManager: PlayerDataManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol

    init(forestManager: ForestDataManagerProtocol, playerManager: PlayerDataManagerProtocol, coreData: CoreDataManagerProtocol) {
        self.forestManager = forestManager
        self.playerManager = playerManager
        self.coreDataManager = coreData
    }
    
    func initializeNewGame() async -> Resource<Bool> {
        let forestInitalized = UserDefaults.standard.bool(forKey: "forestInitalized")
        
        if !forestInitalized {
            let playerResult = playerManager.createInitialPlayer(contextType: .background)
            guard let player = playerResult.data else {
                return Resource.error(error: ForestInitError.playerCreation)
            }
            let forestResult = forestManager.createForest(
                helper: ForestGameHelper(),
                contextType: .background
            )
            guard let forest = forestResult.data else {
                return Resource.error(error: ForestInitError.playerCreation)
            }
            let bindResult = playerManager.bindForest(contextType: .background, forest: forest)
            coreDataManager.save(type: .background)
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "forestInitalized")
            }
            return Resource.success(true)
        }else {
            return Resource.error(error: ForestInitError.alreadyCreated)
        }
    }
}
