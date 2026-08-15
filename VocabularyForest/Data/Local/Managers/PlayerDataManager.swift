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
    }
}

// MARK: - PLAYER DATA MANAGER PROTOCOL

protocol PlayerDataManagerProtocol {
    func fetchSafePlayer(contextType: PlayerDataManager.ContextType) -> PlayerModel?
    func createInitialPlayer(contextType: PlayerDataManager.ContextType) -> Resource<Player>
    func bindForest(contextType: PlayerDataManager.ContextType, forest: Forest) -> Resource<Bool>
    func updatePlayerName(contextType: PlayerDataManager.ContextType, name: String) -> Resource<Bool>
    func fetchAdventureRoadProgress(contextType: PlayerDataManager.ContextType) -> AdventureRoadProgressModel?
    func increaseMonthlyLearnedCount(for questionType: BattleQuestionType, contextType: PlayerDataManager.ContextType) -> Resource<Bool>
}

class PlayerDataManager {
    
    let backgroundContext: NSManagedObjectContext
    let viewContext: NSManagedObjectContext
    
    init(backgroundContext: NSManagedObjectContext, viewContext: NSManagedObjectContext) {
        self.backgroundContext = backgroundContext
        self.viewContext = viewContext
    }
    
}

extension PlayerDataManager: PlayerDataManagerProtocol {
    func fetchAdventureRoadProgress(contextType: ContextType) -> AdventureRoadProgressModel? {
        let context = getContext(context: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context),
                  let daily = forest.dailyActivities else {
                return nil
            }
            return AdventureRoadProgressModel(
                seasonID: daily.adventureSeasonID,
                monthlyShortLearnedCount: Int(daily.monthlyShortLearnedCount),
                monthlyLongLearnedCount: Int(daily.monthlyLongLearnedCount)
            )
        }
    }
    
    func increaseMonthlyLearnedCount(for questionType: BattleQuestionType, contextType: ContextType) -> Resource<Bool> {
        let context = getContext(context: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context),
                  let daily = forest.dailyActivities else {
                return .error(error: PlayerDataError.emptyPlayer)
            }
            
            switch questionType {
            case .learning, .competitive:
                daily.monthlyShortLearnedCount += 1
            case .remainder:
                daily.monthlyLongLearnedCount += 1
            }
            
            daily.lastUpdatedDate = Date()
            save(context: context)
            return .success(true)
        }
    }
    
    func updatePlayerName(contextType: ContextType, name: String) -> Resource<Bool> {
        let context = getContext(context: contextType)
        return context.performAndWait {
            guard let player = getCurrentPlayer(context: context) else { return Resource.error(error: PlayerDataError.emptyPlayer)}
            player.name = name
            save(context: context)
            return Resource.success(true)
        }
    }
    
    func bindForest(contextType: ContextType, forest: Forest) -> Resource<Bool> {
        let context = getContext(context: contextType)
        return context.performAndWait {
            guard let player = getCurrentPlayer(context: context) else { return Resource.error(error: PlayerDataError.emptyPlayer)}
            forest.player = player
            return Resource.success(true)
        }
    }
    
    func createInitialPlayer(contextType: ContextType) -> Resource<Player> {
        let context = getContext(context: contextType)
        return context.performAndWait {
            let player = Player(context: context)
            let safePlayer = PlayerHelper.createDefaultPlayer()
            player.name = safePlayer.name
            player.lastUpdatedDate = safePlayer.lastUpdateDate
            return Resource.success(player)
        }
    }
    
    func fetchSafePlayer(contextType: ContextType) -> PlayerModel? {
        let context = getContext(context: contextType)
        return context.performAndWait {
            let player = getCurrentPlayer(context: context)
            if let name = player?.name, let date = player?.lastUpdatedDate {
                return PlayerModel(name: PlayerHelper.displayName(for: name), lastUpdateDate: date)
            }
            return nil
        }
    }
}

private extension PlayerDataManager {
    
    func getContext(context: PlayerDataManager.ContextType) -> NSManagedObjectContext {
        return switch context {
        case .main:
            viewContext
        case .background:
            backgroundContext
        }
    }
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest? {
        let request: NSFetchRequest<Forest> = Forest.fetchRequest()
        request.fetchLimit = 1
        do {
            return try context.performAndWait { try context.fetch(request).first }
        } catch {
            return nil
        }
    }
    
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
