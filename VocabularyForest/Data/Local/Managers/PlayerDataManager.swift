//
//  PlayerDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import CoreData
import UserNotifications
import DependencyContainer

enum PlayerDataError: Error {
    case emptyPlayer
}

// MARK: - CONTEXT ENUM

extension PlayerDataManager {
    enum ContextType {
        case main
        case background
        
        var context: NSManagedObjectContext {
            let coreDataManager = DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
            return switch self {
            case .main:
                coreDataManager.viewContext
            case .background:
                coreDataManager.backgroundContext
            }
        }
    }
}

// MARK: - PLAYER DATA MANAGER PROTOCOL

protocol PlayerDataManagerProtocol {
    func fetchSafePlayer(contextType: PlayerDataManager.ContextType) -> PlayerModel?
    func createInitialPlayer(contextType: PlayerDataManager.ContextType) -> Resource<Player>
    func bindForest(contextType: PlayerDataManager.ContextType, forest: Forest) -> Resource<Bool>
    func updatePlayerName(contextType: PlayerDataManager.ContextType, name: String) -> Resource<Bool>
}

class PlayerDataManager {
    
}

extension PlayerDataManager: PlayerDataManagerProtocol {
    func updatePlayerName(contextType: ContextType, name: String) -> Resource<Bool> {
        let context = contextType.context
        return context.performAndWait {
            guard let player = getCurrentPlayer(context: context) else { return Resource.error(error: PlayerDataError.emptyPlayer)}
            player.name = name
            save(context: context)
            return Resource.success(true)
        }
    }
    
    func bindForest(contextType: ContextType, forest: Forest) -> Resource<Bool> {
        let context = contextType.context
        return context.performAndWait {
            guard let player = getCurrentPlayer(context: context) else { return Resource.error(error: PlayerDataError.emptyPlayer)}
            forest.player = player
            return Resource.success(true)
        }
    }
    
    func createInitialPlayer(contextType: ContextType) -> Resource<Player> {
        let context = contextType.context
        return context.performAndWait {
            let player = Player(context: context)
            let safePlayer = PlayerHelper.createDefaultPlayer()
            player.name = safePlayer.name
            player.lastUpdatedDate = safePlayer.lastUpdateDate
            return Resource.success(player)
        }
    }
    
    func fetchSafePlayer(contextType: ContextType) -> PlayerModel? {
        let context = contextType.context
        return context.performAndWait {
            let player = getCurrentPlayer(context: context)
            if let name = player?.name, let date = player?.lastUpdatedDate {
                return PlayerModel(name: name, lastUpdateDate: date)
            }
            return nil
        }
    }
}

private extension PlayerDataManager {
    func getCurrentPlayer(context: NSManagedObjectContext) -> Player? {
        let request: NSFetchRequest<Player> = Player.fetchRequest()
        request.fetchLimit = 1
        do {
            return try context.performAndWait { try context.fetch(request).first }
        }catch {
            return nil
        }
    }
    
    func save(context: NSManagedObjectContext) {
        let coreDataManager = DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        coreDataManager.save(in: context)
    }
}
