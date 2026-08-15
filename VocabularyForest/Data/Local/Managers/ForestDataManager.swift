//
//  ForestDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import CoreData
import UserNotifications
import DependencyContainer

// MARK: - FOREST ERROR

enum ForestError: Error, Equatable {
    case emptyList
    case emptyForest
    case saveError
    case safeObject
    case emptyUUID
    case emptyLastDate
    case alreadyExistQuest
    case invalidQuestID
}

extension ForestError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyList:
            return "The list is empty or the expected data could not be found."
            
        case .emptyForest:
            return "Forest data not found. Please create a forest first."
            
        case .saveError:
            return "An error occurred while saving data to the database."
            
        case .safeObject:
            return "Failed to convert the data into a safe object."
            
        case .emptyUUID:
            return "A valid object identifier (UUID) could not be found."
            
        case .emptyLastDate:
            return "The last updated date could not be found."
            
        case .alreadyExistQuest:
            return "This quest already exists in the forest."
        case .invalidQuestID:
            return "This quest haven't been initalized."
        }
    }
}

// MARK: - CONTEXT ENUM

extension ForestDataManager {
    enum ContextType {
        case main
        case background
    }
    enum ForestConstants {
        static let initialLandHealthPercent = Int16(100)
        static let initialRainValue = Int16(0)
        static let initialMoneyValue = Int16(0)
        static let initialDiamond = Int16(0)
    }
}

// MARK: - FOREST DATA PROTOCOL

protocol ForestDataManagerProtocol: AnyObject {
    
    func checkGame(contextType: ForestDataManager.ContextType)
    func checkAndUpdateRain(contextType: ForestDataManager.ContextType) throws
    
    // MARK: Create Helpers
    
    func createForest(contextType: ForestDataManager.ContextType) -> Resource<Forest>
    
    // MARK: Fetch Helpers
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest?
    func fetchForestStatus(contextType: ForestDataManager.ContextType) throws -> ForestStatusModel
    func fetchSafeForest(contextType: ForestDataManager.ContextType) -> Resource<SafeForestModel>
    
    // MARK: - QUEST HELPERS
    
    func fetchQuestTracks(contextType: ForestDataManager.ContextType) -> Resource<[QuestTrackModel]>
    func fetchQuestTrack(id: String, contextType: ForestDataManager.ContextType) throws -> QuestTrackModel
    func importQuest(track: QuestTrackModel, contextType: ForestDataManager.ContextType) throws
    func updateQuest(questTrack: QuestTrackModel, contextType: ForestDataManager.ContextType) throws
    
    // MARK: Update Helpers
    
    func overwriteLocalForest(with safeForest: SafeForestModel, ownerId: String, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func applyRemoteForestChanges(_ changes: RemoteForestChanges, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func bindForestToUser(uid: String?, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateLastSyncCloudTime(date: Date, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func addRainValue(rain: Int, contextType: ForestDataManager.ContextType) throws
    func startRain(contextType: ForestDataManager.ContextType) throws
    func updateMoneyValue(money: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateDiamondValue(diamond: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func claimReward(model: ReadyRewardModel, contextType: ForestDataManager.ContextType) throws
    func markAssetsReady(assetNames: [String], contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateDailySpinTime(time: Date, contextType: ForestDataManager.ContextType) throws
    func updateWeeklyStreak(day: Int, time: Date, contextType: ForestDataManager.ContextType) throws
    func updateClaimedAdventureTier(track: AdventureMemoryTrack, wordCount: Int, time: Date, contextType: ForestDataManager.ContextType) throws
    func registerKillGold(minGold: Int, maxGold: Int, dailyCap: Int, contextType: ForestDataManager.ContextType) throws -> Int
}

class ForestDataManager: ForestDataManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private let mainContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    private let logger: AppLoggerProtocol
    weak var notificationManager: (any NotificationManagerProtocol)?

    // MARK: - INIT

    init(
        mainContext: NSManagedObjectContext,
        backgroundContext: NSManagedObjectContext,
        logger: AppLoggerProtocol = AppLogger.shared
    ) {
        self.mainContext = mainContext
        self.backgroundContext = backgroundContext
        self.logger = logger
    }
    
    // MARK: - UPDATE QUESTS
        /*
    func checkAndResetTimeBasedQuests(helper: ForestGameHelperProtocol, contextType: ContextType) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return .error(error: ForestError.emptyForest)
            }
            
            let now = Date()
            let calendar = Calendar.current
            var hasChanges = false
            
            let lastDaily = forest.lastDailyResetDate ?? Date.distantPast
            if !calendar.isDateInToday(lastDaily) {
                resetQuests(type: .daily, helper: helper, contextType: contextType)
                forest.lastDailyResetDate = now
                hasChanges = true
            }
            
            let lastWeekly = forest.lastWeeklyResetDate ?? Date.distantPast
            let currentWeek = calendar.component(.weekOfYear, from: now)
            let lastResetWeek = calendar.component(.weekOfYear, from: lastWeekly)
            let currentYear = calendar.component(.year, from: now)
            let lastResetYear = calendar.component(.year, from: lastWeekly)
            
            if currentYear != lastResetYear || currentWeek != lastResetWeek {
                resetQuests(type: .weekly, helper: helper, contextType: contextType)
                forest.lastWeeklyResetDate = now
                hasChanges = true
            }
            let lastMonthly = forest.lastMonthlyResetDate ?? Date.distantPast
            let currentMonth = calendar.component(.month, from: now)
            let lastResetMonth = calendar.component(.month, from: lastMonthly)
            
            if currentYear != lastResetYear || currentMonth != lastResetMonth {
                resetQuests(type: .monthly, helper: helper, contextType: contextType)
                forest.lastMonthlyResetDate = now
                hasChanges = true
            }
            
            if hasChanges {
                do {
                    try save(context: context)
                    return .success(true)
                } catch {
                    return .error(error: ForestError.saveError)
                }
            }
            return .success(false)
        }
    }
    */
    
    func checkGame(contextType: ContextType) {
        try? checkAndUpdateRain(contextType: contextType)
        //checkAndResetTimeBasedQuests(helper: ForestGameHelper(), contextType: contextType)
    }
    
    func checkAndUpdateRain(contextType: ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                throw ForestError.emptyForest
            }
            
            let now = Date()
            
            guard let lastUpdate = forest.lastRainUpdateDate else {
                forest.lastRainUpdateDate = now
                try save(context: context)
                return
            }
            
            let decayInterval: TimeInterval = 3600
            let decayAmount: Int16 = 4
            let timeElapsed = now.timeIntervalSince(lastUpdate)
            
            if timeElapsed >= decayInterval {
                let hoursPassed = Int(timeElapsed / decayInterval)
                if hoursPassed > 0 {
                    let totalDecay = Int16(hoursPassed) * decayAmount
                    let oldRainValue = forest.landHealthPercent
                    let newRainValue = max(0, oldRainValue - totalDecay)
                    
                    forest.landHealthPercent = newRainValue
                    forest.lastRainUpdateDate = lastUpdate.addingTimeInterval(TimeInterval(hoursPassed) * decayInterval)
                    do {
                        try save(context: context)
                        scheduleHealthNotifications(contextType: contextType)
                    } catch {
                        throw ForestError.saveError
                    }
                }
            }
            
            scheduleHealthNotifications(contextType: contextType)
        }
    }
    
}

// MARK: - CREATE HELPERS

extension ForestDataManager {
    
    func createForest(contextType: ContextType) -> Resource<Forest> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let forest = Forest(context: context)
            forest.rainValue = ForestConstants.initialRainValue
            forest.isRaining = false
            forest.landHealthPercent = ForestConstants.initialLandHealthPercent
            forest.landStatus = true
            forest.moneyValue = ForestConstants.initialMoneyValue
            forest.lastUpdatedDate = Date()
            forest.forestId = UUID()
            let dailyActivities = DailyActivities(context: context)
            dailyActivities.lastUpdatedDate = Date()
            forest.dailyActivities = dailyActivities
            for sculptureModel in baseSculptureList {
                let sculpture = Sculpture(context: context)
                sculpture.id = sculptureModel.id
                sculpture.assetName = sculptureModel.assetName
                sculpture.createdDate = sculptureModel.createdDate
                sculpture.characterName = generateRandomName(type: .sculpture)
                sculpture.xPosition = sculptureModel.xPosition
                sculpture.yPosition = sculptureModel.yPosition
                sculpture.lastUpdatedDate = Date()
                sculpture.assetSourceString = ImageSourceType.appAssets.rawValue
                sculpture.posterKey = sculptureModel.assetName
                sculpture.posterSourceString = ImageSourceType.appAssets.rawValue
                sculpture.assetReady = true
                forest.addToSculptures(sculpture)
            }
            do {
                try save(context: context)
                return Resource.success(forest)
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
        }
    }
}

// MARK: - QUEST HELPERS

extension ForestDataManager {
    func importQuest(track: QuestTrackModel, contextType: ForestDataManager.ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                throw ForestError.emptyForest
            }
            if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest], let _ = quests.first(where: { $0.id == track.id }) {
                throw ForestError.alreadyExistQuest
            } else {
                let quest = Quest(context: context)
                quest.currentProgressCount = Int16(track.currentProgressCount)
                quest.id = track.id
                quest.status = track.status.valueForCoreData
                quest.lastUpdatedDate = track.lastUpdatedDate
                forest.addToQuests(quest)
                try save(context: context)
            }
        }
    }
}

// MARK: - FETCH HELPERS

extension ForestDataManager {
    
    func fetchQuestTrack(id: String, contextType: ForestDataManager.ContextType) throws -> QuestTrackModel {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                throw ForestError.emptyForest
            }
            if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest], let coreDataQuest = quests.first(where: { $0.id == id }) {
                do {
                    let questTrack = try coreDataQuest.safeObject(context: context)
                    return questTrack
                }catch {
                    throw error
                }
            } else {
                throw ForestError.emptyForest
            }
        }
    }
    
    func fetchSafeForest(contextType: ForestDataManager.ContextType) -> Resource<SafeForestModel> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            do {
                let safeForest = try forest.safeObject(context: context)
                return Resource.success(safeForest)
            }catch {
                return Resource.error(error: ForestError.safeObject)
            }
        }
    }
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest? {
        let request: NSFetchRequest<Forest> = Forest.fetchRequest()
        request.fetchLimit = 1
        do {
            return try context.performAndWait { try context.fetch(request).first }
        }catch {
            return nil
        }
    }
    
    func fetchForestStatus(contextType: ContextType) throws -> ForestStatusModel {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                throw ForestError.emptyForest
            }
            let model = ForestStatusModel(
                rainValue: Int(forest.rainValue),
                landHealthPercentage: Int(forest.landHealthPercent),
                landStatus: forest.landStatus,
                gold: Int(forest.moneyValue),
                diamond: Int(forest.diamondValue)
            )
            return model
        }
    }
    
    func fetchQuestTracks(contextType: ContextType) -> Resource<[QuestTrackModel]> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            var questList: [QuestTrackModel] = []
            if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest] {
                for quest in quests {
                    do {
                        let questModel = try quest.safeObject(context: context)
                        questList.append(questModel)
                    } catch {
                        logger.error("Quest could not be mapped to its safe model: \(error.localizedDescription)", category: .forest)
                        return Resource.error(error: SafeModelError.invalidMapping)
                    }
                }
            }
            if questList.isEmpty {
                return Resource.error(error: ForestError.emptyList)
            }else {
                return Resource.success(questList)
            }
        }
    }
    
}

// MARK: - UPDATE HELPERS

extension ForestDataManager {
    
    func claimReward(model: ReadyRewardModel, contextType: ForestDataManager.ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                throw ForestError.emptyForest
            }
            
            switch model.category {
            case .animal:
                let animalModel = createSafeAnimal(model: model)
                let animal = Animal(context: context)
                animal.id = animalModel.id
                animal.characterName = animalModel.characterName
                animal.createdDate = animalModel.createdDate
                animal.assetName = animalModel.assetName
                animal.healthValue = Int16(animalModel.healthValue)
                animal.isAlive = animalModel.isAlive
                animal.xPosition = animalModel.xPosition
                animal.yPosition = animalModel.yPosition
                animal.lastUpdatedDate = animalModel.lastUpdatedDate
                animal.assetSourceString = animalModel.assetSource.rawValue
                animal.posterKey = animalModel.poster.key
                animal.posterSourceString = animalModel.poster.source.rawValue
                animal.rewardId = animalModel.rewardId
                animal.assetReady = animalModel.assetReady
                forest.addToAnimals(animal)

            case .plant:
                let treeModel = createSafePlant(model: model, contextType: contextType)
                let tree = Tree(context: context)
                tree.id = treeModel.id
                tree.createdDate = treeModel.createdDate
                tree.characterName = treeModel.characterName
                tree.healthValue = Int16(treeModel.treeHealthValue)
                tree.isAlive = treeModel.isAlive
                tree.assetName = treeModel.assetName
                tree.xPosition = treeModel.xPosition
                tree.yPosition = treeModel.yPosition
                tree.assetSourceString = treeModel.assetSource.rawValue
                tree.posterKey = treeModel.poster.key
                tree.posterSourceString = treeModel.poster.source.rawValue
                tree.lastUpdatedDate = treeModel.lastUpdatedDate
                tree.rewardId = treeModel.rewardId
                tree.assetReady = treeModel.assetReady
                forest.addToTrees(tree)

            case .sculpture:
                let sculptureModel = createSafeSculpture(model: model, contextType: contextType)
                let sculpture = Sculpture(context: context)
                sculpture.id = sculptureModel.id
                sculpture.assetName = sculptureModel.assetName
                sculpture.createdDate = sculptureModel.createdDate
                sculpture.characterName = sculptureModel.characterName
                sculpture.xPosition = sculptureModel.xPosition
                sculpture.yPosition = sculptureModel.yPosition
                sculpture.lastUpdatedDate = sculptureModel.lastUpdatedDate
                sculpture.assetSourceString = sculptureModel.assetSource.rawValue
                sculpture.posterKey = sculptureModel.poster.key
                sculpture.posterSourceString = sculptureModel.poster.source.rawValue
                sculpture.rewardId = sculptureModel.rewardId
                sculpture.assetReady = sculptureModel.assetReady
                forest.addToSculptures(sculpture)

            case .gold:
                forest.moneyValue += Int16(model.rewardCount)
                
            case .water:
                forest.rainValue += Int16(model.rewardCount)
                
            case .diamond:
                forest.diamondValue += Int16(model.rewardCount)
            }
            
            forest.lastUpdatedDate = Date()
            
            do {
                try save(context: context)
            } catch {
                throw error
            }
        }
    }
    
    /// Marks every entity (animal/tree/sculpture) using a disk-verified asset as ready.
    /// Leaves `lastUpdatedDate` untouched: `assetReady` is device-local state and is never synced to the cloud.
    func markAssetsReady(assetNames: [String], contextType: ContextType) -> Resource<Bool> {
        guard !assetNames.isEmpty else { return Resource.success(false) }
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            do {
                var changed = false
                for entityName in CoreDataConstant.forestAssetEntityNames {
                    changed = try markEntitiesReady(
                        entityName: entityName,
                        assetNames: assetNames,
                        forest: forest,
                        context: context
                    ) || changed
                }
                guard changed else { return Resource.success(false) }
                try save(context: context)
                return Resource.success(true)
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
        }
    }

    func overwriteLocalForest(
        with safeForest: SafeForestModel,
        ownerId: String,
        contextType: ContextType
    ) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            if let oldForest = getCurrentForest(context: context) {
                context.delete(oldForest)
            }
            let newForest = Forest(context: context)
            newForest.forestId = safeForest.forestId
            newForest.ownerId = ownerId
            newForest.moneyValue = Int16(safeForest.moneyValue)
            newForest.diamondValue = Int16(safeForest.diamondValue)
            newForest.rainValue = Int16(safeForest.rainValue)
            newForest.landHealthPercent = Int16(safeForest.landHealthPercent)
            newForest.landStatus = safeForest.landStatus
            newForest.lastRainUpdateDate = safeForest.lastRainUpdateDate
            newForest.lastDailyResetDate = safeForest.lastDailyResetDate
            newForest.lastWeeklyResetDate = safeForest.lastWeeklyResetDate
            newForest.lastMonthlyResetDate = safeForest.lastMonthlyResetDate
            newForest.lastUpdatedDate = safeForest.lastUpdatedDate
            newForest.lastSyncCloudTime = Date()
            
            for treeModel in safeForest.trees {
                let tree = Tree(context: context)
                tree.id = treeModel.id
                tree.assetName = treeModel.assetName
                tree.characterName = treeModel.characterName
                tree.createdDate = treeModel.createdDate
                tree.healthValue = Int16(treeModel.treeHealthValue)
                tree.isAlive = treeModel.isAlive
                tree.lastUpdatedDate = treeModel.lastUpdatedDate
                tree.xPosition = treeModel.xPosition
                tree.yPosition = treeModel.yPosition
                tree.assetSourceString = treeModel.assetSource.rawValue
                tree.posterKey = treeModel.poster.key
                tree.posterSourceString = treeModel.poster.source.rawValue
                tree.rewardId = treeModel.rewardId
                tree.assetReady = treeModel.assetReady
                newForest.addToTrees(tree)
            }
            
            for animalModel in safeForest.animals {
                let animal = Animal(context: context)
                animal.id = animalModel.id
                animal.assetName = animalModel.assetName
                animal.characterName = animalModel.characterName
                animal.createdDate = animalModel.createdDate
                animal.healthValue = Int16(animalModel.healthValue)
                animal.isAlive = animalModel.isAlive
                animal.lastUpdatedDate = animalModel.lastUpdatedDate
                animal.xPosition = animalModel.xPosition
                animal.yPosition = animalModel.yPosition
                animal.assetSourceString = animalModel.assetSource.rawValue
                animal.posterKey = animalModel.poster.key
                animal.posterSourceString = animalModel.poster.source.rawValue
                animal.rewardId = animalModel.rewardId
                animal.assetReady = animalModel.assetReady
                newForest.addToAnimals(animal)
            }
            
            for sculptureModel in safeForest.sculptures {
                let sculpture = Sculpture(context: context)
                sculpture.id = sculptureModel.id
                sculpture.assetName = sculptureModel.assetName
                sculpture.characterName = sculptureModel.characterName
                sculpture.createdDate = sculptureModel.createdDate
                sculpture.lastUpdatedDate = sculptureModel.lastUpdatedDate
                sculpture.xPosition = sculptureModel.xPosition
                sculpture.yPosition = sculptureModel.yPosition
                sculpture.assetSourceString = sculptureModel.assetSource.rawValue
                sculpture.posterKey = sculptureModel.poster.key
                sculpture.posterSourceString = sculptureModel.poster.source.rawValue
                sculpture.rewardId = sculptureModel.rewardId
                sculpture.assetReady = sculptureModel.assetReady
                newForest.addToSculptures(sculpture)
            }
            
            let player = Player(context: context)
            player.name = safeForest.player.name
            player.lastUpdatedDate = safeForest.player.lastUpdateDate
            newForest.player = player
            
            let dailyActivities = DailyActivities(context: context)
            dailyActivities.adventureSeasonID = safeForest.dailyActivities.adventureSeasonID
            dailyActivities.claimedLongTiers = safeForest.dailyActivities.claimedLongTiers
            dailyActivities.claimedShortTiers = safeForest.dailyActivities.claimedShortTiers
            dailyActivities.monthlyLongLearnedCount = Int16(safeForest.dailyActivities.monthlyLongLearnedCount)
            dailyActivities.monthlyShortLearnedCount = Int16(safeForest.dailyActivities.monthlyShortLearnedCount)
            dailyActivities.weeklyStreakLastClaimDate = safeForest.dailyActivities.weeklyStreakLastClaimDate
            dailyActivities.weeklyStreakCurrentDay = Int16(safeForest.dailyActivities.weeklyStreakCurrentDay)
            dailyActivities.lastFetchDate = safeForest.dailyActivities.lastFetchDate
            dailyActivities.fixedTimeZone = safeForest.dailyActivities.fixedTimeZone
            dailyActivities.dailySpinLastUsedDate = safeForest.dailyActivities.dailySpinLastUsedDate
            dailyActivities.lastUpdatedDate = safeForest.dailyActivities.lastUpdatedDate
            dailyActivities.dailyKillGoldCount = Int16(safeForest.dailyActivities.dailyKillGoldCount)
            dailyActivities.killGoldLastResetDate = safeForest.dailyActivities.killGoldLastResetDate
            newForest.dailyActivities = dailyActivities
            
            for questModel in safeForest.quests {
                let quest = Quest(context: context)
                quest.id = questModel.id
                quest.currentProgressCount = Int16(questModel.currentProgressCount)
                quest.lastUpdatedDate = questModel.lastUpdatedDate
                quest.status = questModel.status.valueForCoreData
                newForest.addToQuests(quest)
            }
            
            do {
                try save(context: context)
                return .success(true)
            } catch {
                return .error(error: ForestError.saveError)
            }
        }
    }
    
    func applyRemoteForestChanges(_ changes: RemoteForestChanges, contextType: ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return .error(error: ForestError.emptyForest)
            }

            // Remote timestamps are written as-is on purpose: refreshing them here would
            // make the next delta sync push the same data straight back to the cloud.
            if let metadata = changes.metadata {
                forest.moneyValue = Int16(metadata.moneyValue)
                forest.diamondValue = Int16(metadata.diamondValue)
                forest.rainValue = Int16(metadata.rainValue)
                forest.landHealthPercent = Int16(metadata.landHealthPercent)
                forest.lastUpdatedDate = metadata.lastUpdatedDate
            }

            let existingTrees = forest.trees as? Set<Tree> ?? []
            for model in changes.trees {
                let tree: Tree
                if let existing = existingTrees.first(where: { $0.id == model.id }) {
                    tree = existing
                } else {
                    tree = Tree(context: context)
                    tree.id = model.id
                    tree.createdDate = model.createdDate
                    forest.addToTrees(tree)
                }
                tree.assetName = model.assetName
                tree.characterName = model.characterName
                tree.healthValue = Int16(model.treeHealthValue)
                tree.isAlive = model.isAlive
                tree.lastUpdatedDate = model.lastUpdatedDate
                tree.xPosition = model.xPosition
                tree.yPosition = model.yPosition
                tree.assetSourceString = model.assetSource.rawValue
                tree.posterKey = model.poster.key
                tree.posterSourceString = model.poster.source.rawValue
                tree.rewardId = model.rewardId
                tree.assetReady = model.assetReady
            }

            let existingAnimals = forest.animals as? Set<Animal> ?? []
            for model in changes.animals {
                let animal: Animal
                if let existing = existingAnimals.first(where: { $0.id == model.id }) {
                    animal = existing
                } else {
                    animal = Animal(context: context)
                    animal.id = model.id
                    animal.createdDate = model.createdDate
                    forest.addToAnimals(animal)
                }
                animal.assetName = model.assetName
                animal.characterName = model.characterName
                animal.healthValue = Int16(model.healthValue)
                animal.isAlive = model.isAlive
                animal.lastUpdatedDate = model.lastUpdatedDate
                animal.xPosition = model.xPosition
                animal.yPosition = model.yPosition
                animal.assetSourceString = model.assetSource.rawValue
                animal.posterKey = model.poster.key
                animal.posterSourceString = model.poster.source.rawValue
                animal.rewardId = model.rewardId
                animal.assetReady = model.assetReady
            }

            let existingSculptures = forest.sculptures as? Set<Sculpture> ?? []
            for model in changes.sculptures {
                let sculpture: Sculpture
                if let existing = existingSculptures.first(where: { $0.id == model.id }) {
                    sculpture = existing
                } else {
                    sculpture = Sculpture(context: context)
                    sculpture.id = model.id
                    sculpture.createdDate = model.createdDate
                    forest.addToSculptures(sculpture)
                }
                sculpture.assetName = model.assetName
                sculpture.characterName = model.characterName
                sculpture.lastUpdatedDate = model.lastUpdatedDate
                sculpture.xPosition = model.xPosition
                sculpture.yPosition = model.yPosition
                sculpture.assetSourceString = model.assetSource.rawValue
                sculpture.posterKey = model.poster.key
                sculpture.posterSourceString = model.poster.source.rawValue
                sculpture.rewardId = model.rewardId
                sculpture.assetReady = model.assetReady
            }

            let existingQuests = forest.quests as? Set<Quest> ?? []
            for model in changes.quests {
                let quest: Quest
                if let existing = existingQuests.first(where: { $0.id == model.id }) {
                    quest = existing
                } else {
                    quest = Quest(context: context)
                    quest.id = model.id
                    forest.addToQuests(quest)
                }
                quest.currentProgressCount = Int16(model.currentProgressCount)
                quest.lastUpdatedDate = model.lastUpdatedDate
                quest.status = model.status.valueForCoreData
            }

            if let playerModel = changes.player {
                let player = forest.player ?? Player(context: context)
                player.name = playerModel.name
                player.lastUpdatedDate = playerModel.lastUpdateDate
                forest.player = player
            }

            if let dailyModel = changes.dailyActivities {
                let dailyActivities = forest.dailyActivities ?? DailyActivities(context: context)
                dailyActivities.adventureSeasonID = dailyModel.adventureSeasonID
                dailyActivities.claimedLongTiers = dailyModel.claimedLongTiers
                dailyActivities.claimedShortTiers = dailyModel.claimedShortTiers
                dailyActivities.monthlyLongLearnedCount = Int16(dailyModel.monthlyLongLearnedCount)
                dailyActivities.monthlyShortLearnedCount = Int16(dailyModel.monthlyShortLearnedCount)
                dailyActivities.weeklyStreakLastClaimDate = dailyModel.weeklyStreakLastClaimDate
                dailyActivities.weeklyStreakCurrentDay = Int16(dailyModel.weeklyStreakCurrentDay)
                dailyActivities.lastFetchDate = dailyModel.lastFetchDate
                dailyActivities.fixedTimeZone = dailyModel.fixedTimeZone
                dailyActivities.dailySpinLastUsedDate = dailyModel.dailySpinLastUsedDate
                dailyActivities.lastUpdatedDate = dailyModel.lastUpdatedDate
                dailyActivities.dailyKillGoldCount = Int16(dailyModel.dailyKillGoldCount)
                dailyActivities.killGoldLastResetDate = dailyModel.killGoldLastResetDate
                forest.dailyActivities = dailyActivities
            }

            do {
                try save(context: context)
                return .success(true)
            } catch {
                return .error(error: ForestError.saveError)
            }
        }
    }

    func bindForestToUser(uid: String?, contextType: ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return .error(error: ForestError.emptyForest)
            }
            forest.ownerId = uid
            do {
                try save(context: context)
                return .success(true)
            } catch {
                return .error(error: ForestError.saveError)
            }
        }
    }
    
    func updateLastSyncCloudTime(date: Date, contextType: ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return .error(error: ForestError.emptyForest)
            }
            
            forest.lastSyncCloudTime = date
            
            do {
                try save(context: context)
            } catch {
                return .error(error: ForestError.saveError)
            }
            
            return .success(true)
        }
    }
    
    func updateQuest(questTrack: QuestTrackModel, contextType: ContextType) throws {
        let context = getContext(for: contextType)
        guard let forest = getCurrentForest(context: context) else {
            throw ForestError.saveError
        }
        try context.performAndWait {
            if let questList = forest.quests, let quests = questList.allObjects as? [Quest] {
                guard let quest = quests.first(where: { $0.id == questTrack.id }) else { throw ForestError.invalidQuestID
                }
                quest.currentProgressCount = Int16(questTrack.currentProgressCount)
                quest.status = questTrack.status.valueForCoreData
                quest.lastUpdatedDate = questTrack.lastUpdatedDate
                try save(context: context)
            }else {
                throw ForestError.emptyList
            }
        }
    }
        
    func addRainValue(rain: Int, contextType: ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                throw ForestError.saveError
            }
            forest.rainValue += Int16(rain)
            forest.lastUpdatedDate = Date()
            try save(context: context)
        }
    }
    
    func startRain(contextType: ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                throw ForestError.saveError
            }
            forest.rainValue -= Int16(ForestConstant.rainCostValue)
            forest.landStatus = true
            forest.landHealthPercent = Int16(ForestConstant.healthyLandHealth)
            forest.lastUpdatedDate = Date()
            try save(context: context)
        }
    }
    
    func updateMoneyValue(money: Int, contextType: ContextType)  -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.saveError)
            }
            forest.moneyValue += Int16(money)
            forest.lastUpdatedDate = Date()
            do {
                try save(context: context)
            }
            catch {
                return Resource.error(error: error)
            }
            return Resource.success(true)
        }
    }
    
    func updateDiamondValue(diamond: Int, contextType: ContextType)  -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.saveError)
            }
            forest.diamondValue += Int16(diamond)
            forest.lastUpdatedDate = Date()
            do {
                try save(context: context)
            }
            catch {
                return Resource.error(error: error)
            }
            return Resource.success(true)
        }
    }
    
    func updateDailySpinTime(time: Date, contextType: ForestDataManager.ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else { throw ForestError.emptyForest }
            guard let activities = forest.dailyActivities else {
                throw ForestAdventureError.emptyForestActivities
            }
            activities.dailySpinLastUsedDate = time
            activities.lastUpdatedDate = time
            try save(context: context)
        }
    }
    
    func updateWeeklyStreak(day: Int, time: Date, contextType: ForestDataManager.ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else { throw ForestError.emptyForest }
            guard let activities = forest.dailyActivities else {
                throw ForestAdventureError.emptyForestActivities
            }
            /// Freeze the timezone on first claim so day calculations stay consistent
            if activities.fixedTimeZone == nil {
                activities.fixedTimeZone = TimeZone.current.identifier
            }
            activities.weeklyStreakCurrentDay = Int16(day)
            activities.weeklyStreakLastClaimDate = time
            activities.lastUpdatedDate = time
            try save(context: context)
        }
    }

    func updateClaimedAdventureTier(track: AdventureMemoryTrack, wordCount: Int, time: Date, contextType: ForestDataManager.ContextType) throws {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else { throw ForestError.emptyForest }
            guard let activities = forest.dailyActivities else {
                throw ForestAdventureError.emptyForestActivities
            }
            switch track {
            case .shortTerm:
                activities.claimedShortTiers = AdventureTierCoder.append(wordCount, to: activities.claimedShortTiers)
            case .longTerm:
                activities.claimedLongTiers = AdventureTierCoder.append(wordCount, to: activities.claimedLongTiers)
            }
            activities.lastUpdatedDate = time
            try save(context: context)
        }
    }
    
    /// Grants random gold for an enemy kill while respecting the daily kill cap.
    /// Returns the granted amount, or 0 when the cap is already reached.
    func registerKillGold(minGold: Int, maxGold: Int, dailyCap: Int, contextType: ContextType) throws -> Int {
        let context = getContext(for: contextType)
        return try context.performAndWait {
            guard let forest = getCurrentForest(context: context) else { throw ForestError.emptyForest }
            guard let activities = forest.dailyActivities else {
                throw ForestAdventureError.emptyForestActivities
            }
            let now = Date()
            /// Lazy daily reset: clear the counter on the first kill of a new day
            let lastReset = activities.killGoldLastResetDate ?? Date.distantPast
            if !Calendar.current.isDate(lastReset, inSameDayAs: now) {
                activities.dailyKillGoldCount = 0
                activities.killGoldLastResetDate = now
            }
            guard Int(activities.dailyKillGoldCount) < dailyCap else { return 0 }
            let safeMax = max(minGold, maxGold)
            let grantedGold = Int.random(in: minGold...safeMax)
            activities.dailyKillGoldCount += 1
            activities.lastUpdatedDate = now
            forest.moneyValue += Int16(grantedGold)
            forest.lastUpdatedDate = now
            try save(context: context)
            return grantedGold
        }
    }
}

// MARK: - PRIVATE HELPERS

private extension ForestDataManager {
    
    private func getContext(for type: ContextType) -> NSManagedObjectContext {
        switch type {
        case .main:
            return mainContext
        case .background:
            return backgroundContext
        }
    }
    
    func scheduleHealthNotifications(contextType: ContextType) {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else { return }
            
            Task { @MainActor [weak self] in
                self?.notificationManager?.cancelHealthNotifications()
            }
            
            let currentHealth = Int(forest.landHealthPercent)
            let decayPerHour: Double = 4.0
            
            let targets = [50, 20, 10, 0]
            for target in targets {
                if currentHealth > target {
                    let diff = currentHealth - target
                    let hoursUntilDrop = Double(diff) / decayPerHour
                    let secondsUntilDrop = hoursUntilDrop * 3600
                    Task { @MainActor in
                        notificationManager?.scheduleHealthNotification(
                            targetValue: target,
                            timeInterval: secondsUntilDrop
                        )
                    }
                }
            }
        }
    }
    
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.error("Forest context save failed: \(error.localizedDescription)", category: .forest)
            throw error
        }
    }
        
    func setupQuests(questList: [QuestModel], contextType: ContextType) {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else { return }
            for model in questList {
                let quest = Quest(context: context)
                quest.id = model.id
                quest.status = model.status.valueForCoreData
                quest.currentProgressCount = 0
                quest.lastUpdatedDate = model.lastUpdatedDate
                forest.addToQuests(quest)
            }
            do {
                try save(context: context)
            } catch {
                logger.error("Quest setup save failed: \(error.localizedDescription)", category: .forest)
            }
        }
    }
}

// MARK: - POSITION HELPERS

private extension ForestDataManager {
        
    private enum ForestObjectType {
        case tree
        case sculpture
    }
    
    /// One fetch per entity, scoped to the given forest; the caller batches the single save.
    func markEntitiesReady(
        entityName: String,
        assetNames: [String],
        forest: Forest,
        context: NSManagedObjectContext
    ) throws -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(
            format: "%K IN %@ AND %K == NO AND %K == %@",
            CoreDataConstant.assetNameKey, assetNames,
            CoreDataConstant.assetReadyKey,
            CoreDataConstant.forestRelationName, forest
        )
        let entities = try context.fetch(request)
        for entity in entities {
            entity.setValue(true, forKey: CoreDataConstant.assetReadyKey)
        }
        return !entities.isEmpty
    }

    private func generateValidPosition(for type: ForestObjectType, contextType: ContextType) -> (x: Double, y: Double) {
        let context = getContext(for: contextType)
        let xRange = -0.33...0.56
        let yRange = 0.18...0.5
        
        let minDistance: Double = (type == .tree) ? 0.15 : 0.20
        
        let maxAttempts = 100
        
        var existingPositions: [(Double, Double)] = []
        
        if let forest = getCurrentForest(context: context) {
            if let trees = forest.trees?.allObjects as? [Tree] {
                existingPositions.append(contentsOf: trees.map { ($0.xPosition, $0.yPosition) })
            }
            if let sculptures = forest.sculptures?.allObjects as? [Sculpture] {
                existingPositions.append(contentsOf: sculptures.map { ($0.xPosition, $0.yPosition) })
            }
        }
        
        for _ in 0..<maxAttempts {
            let randomX = Double.random(in: xRange)
            let randomY = Double.random(in: yRange)
            var hasCollision = false
            for (exX, exY) in existingPositions {
                let dx = randomX - exX
                let dy = randomY - exY
                let distance = sqrt(dx*dx + dy*dy)
                
                if distance < minDistance {
                    hasCollision = true
                    break
                }
            }
            if !hasCollision {
                return (randomX, randomY)
            }
        }
        return (Double.random(in: xRange), Double.random(in: yRange))
    }
}

private extension ForestDataManager {
    func createSafeAnimal(model: ReadyRewardModel) -> AnimalModel {
        return AnimalModel(
            id: UUID(),
            assetName: model.assetSource.key,
            createdDate: Date(),
            characterName: generateRandomName(type: .animal),
            assetSource: model.assetSource.source,
            poster: model.posterImage,
            healthValue: 10,
            isAlive: true,
            xPosition: CGFloat.random(in: -50...50),
            yPosition: CGFloat.random(in: -50...50),
            lastUpdatedDate: Date(),
            rewardId: model.id
        )
    }
    func createSafePlant(model: ReadyRewardModel, contextType: ContextType) -> TreeModel {
        let position = generateValidPosition(for: .tree, contextType: contextType)
        return TreeModel(
            id: UUID(),
            assetName: model.assetSource.key,
            createdDate: Date(),
            characterName: generateRandomName(type: .plant),
            assetSource: model.assetSource.source,
            poster: model.posterImage,
            isAlive: true,
            treeHealthValue: 5,
            xPosition: CGFloat(position.x),
            yPosition: CGFloat(position.y),
            lastUpdatedDate: Date(),
            rewardId: model.id
        )
    }
    func createSafeSculpture(model: ReadyRewardModel, contextType: ContextType) -> SculptureModel {
        let position = generateValidPosition(for: .sculpture, contextType: contextType)
        return SculptureModel(
            id: UUID(),
            assetName: model.assetSource.key,
            createdDate: Date(),
            characterName: generateRandomName(type: .sculpture),
            assetSource: model.assetSource.source,
            poster: model.posterImage,
            xPosition: CGFloat(position.x),
            yPosition: CGFloat(position.y),
            lastUpdatedDate: Date(),
            rewardId: model.id
        )
    }
}
