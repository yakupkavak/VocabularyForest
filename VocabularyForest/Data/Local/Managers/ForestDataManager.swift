//
//  ForestDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import CoreData
import UserNotifications
import DependencyContainer

enum ForestError: Error {
    case emptyList
    case emptyForest
    case saveError
    case safeObject
    case error(error: Error)
    case emptyUUID
    case emptyLastDate
}

// MARK: - CONTEXT ENUM

extension ForestDataManager {
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
    enum ForestConstants {
        static let initialLandHealthPercent = Int16(100)
        static let initialRainValue = Int16(0)
        static let initialMoneyValue = Int16(0)
        static let initialDiamond = Int16(0)
    }
}

// MARK: - FOREST DATA PROTOCOL

protocol ForestDataManagerProtocol: AnyObject {
    
    // MARK: Update Quests & Game State
    
    func checkAndResetTimeBasedQuests(helper: ForestGameHelperProtocol, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func checkGame(contextType: ForestDataManager.ContextType)
    func checkAndUpdateRain(contextType: ForestDataManager.ContextType) -> Resource<Bool>
    
    // MARK: Create Helpers
    
    func createForest(helper: ForestGameHelperProtocol, contextType: ForestDataManager.ContextType) -> Resource<Forest>
    
    // MARK: Fetch Helpers
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest?
    func fetchForestStatus(contextType: ForestDataManager.ContextType) -> Resource<ForestStatusModel>
    func fetchQuests(contextType: ForestDataManager.ContextType) -> Resource<[QuestModel]>
    func fetchSafeForest(contextType: ForestDataManager.ContextType) -> Resource<SafeForestModel>
    
    // MARK: Update Helpers
    
    func overwriteLocalForest(with safeForest: SafeForestModel, ownerId: String, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func bindForestToUser(uid: String, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateLastSyncCloudTime(date: Date, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func claimQuestReward(quest: QuestModel, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func winGame(gameLevel: GameLevel, battleEnemyMode: BattleEnemyModel, gameType: BattleQuestionType, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func correctAnswer(questionType: BattleQuestionType, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateRainValue(rain: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func startRain(contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateMoneyValue(money: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateDiamondValue(diamond: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func claimReward(model: QuestRewardModel, contextType: ForestDataManager.ContextType) -> Resource<Bool>
}

class ForestDataManager: ForestDataManagerProtocol {
    
    // MARK: - PROPERTIES
    
    weak var notificationManager: (any NotificationManagerProtocol)?
    
    // MARK: - INIT
    
    init() { }
    
    // MARK: - UPDATE QUESTS
        
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
    
    func checkGame(contextType: ContextType) {
        checkAndUpdateRain(contextType: contextType)
        checkAndResetTimeBasedQuests(helper: ForestGameHelper(), contextType: contextType)
    }
    
    func checkAndUpdateRain(contextType: ContextType) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return .error(error: ForestError.emptyForest)
            }
            
            let now = Date()
            
            guard let lastUpdate = forest.lastRainUpdateDate else {
                forest.lastRainUpdateDate = now
                try? save(context: context)
                return .success(true)
            }
            
            let decayInterval: TimeInterval = 3600
            let decayAmount: Int16 = Int16(ForestConstant.rainDecayPerHour)
            let timeElapsed = now.timeIntervalSince(lastUpdate)
            
            if timeElapsed >= decayInterval {
                let hoursPassed = Int(timeElapsed / decayInterval)
                if hoursPassed > 0 {
                    let totalDecay = Int16(hoursPassed) * decayAmount
                    let oldLandHealthValue = forest.landHealthPercent
                    let oldStoredRainValue = forest.rainValue
                    let newLandHealthValue = max(0, oldLandHealthValue - totalDecay)
                    let newStoredRainValue = max(0, oldStoredRainValue - totalDecay)

                    forest.landHealthPercent = newLandHealthValue
                    forest.rainValue = newStoredRainValue
                    forest.lastRainUpdateDate = lastUpdate.addingTimeInterval(TimeInterval(hoursPassed) * decayInterval)
                    do {
                        try save(context: context)
                        scheduleHealthNotifications(contextType: contextType)
                    } catch {
                        return .error(error: ForestError.saveError)
                    }
                }
            }
            
            scheduleHealthNotifications(contextType: contextType)
            return .success(true)
        }
    }
    
}

// MARK: - PRIVATE HELPERS

private extension ForestDataManager {
    
    func resetQuests(type: QuestType, helper: ForestGameHelperProtocol, contextType: ContextType) {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: contextType.context) else { return }
            if let currentQuests = forest.quests?.allObjects as? [Quest] {
                let oldQuests = currentQuests.filter {
                    $0.type == type.valueForCoreData
                }
                for oldQuest in oldQuests {
                    context.delete(oldQuest)
                }
            }
            
            var newQuestsModels: [QuestModel] = []
            switch type {
            case .daily:
                newQuestsModels = helper.initalizeDailyQuests()
            case .weekly:
                newQuestsModels = helper.initalizeWeeklyQuests()
            case .monthly:
                newQuestsModels = helper.initalizeMonthlyQuests()
            case .special:
                break
            }
            setupQuests(questList: newQuestsModels, contextType: contextType)
        }
    }
    
    func scheduleHealthNotifications(contextType: ContextType) {
        contextType.context.performAndWait {
            let context = contextType.context
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
            print("Core data couldn't saved -> \(error.localizedDescription)")
            throw error
        }
    }
        
    func setupQuests(questList: [QuestModel], contextType: ContextType) {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else { return }
            for model in questList {
                let quest = Quest(context: context)
                quest.id = model.id
                quest.type = model.type.valueForCoreData
                quest.title = model.title
                quest.description_quest = model.description
                quest.rewardType = model.reward.typeName
                quest.rewardValue = model.reward.coreDataValueString
                quest.status = model.status.valueForCoreData
                quest.targetCount = Int16(model.targetCount)
                quest.currentProgressCount = 0
                quest.gameLevel = model.gameLevel.valueForCoreData
                quest.battleEnemyModel = model.battleEnemyModel.valueForCoreData
                quest.questType = model.questionType.valueForCoreData
                quest.lastUpdatedDate = model.lastUpdatedDate
                forest.addToQuests(quest)
            }
            do {
                try save(context: context)
            } catch {
                print("Setup quest error -> \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - CREATE HELPERS

extension ForestDataManager {
    
    func createForest(helper: ForestGameHelperProtocol, contextType: ContextType) -> Resource<Forest> {
        contextType.context.performAndWait {
            let context = contextType.context
            let dailyQuests = helper.initalizeDailyQuests()
            let weeklyQuests = helper.initalizeWeeklyQuests()
            let monthlyQuests = helper.initalizeMonthlyQuests()
            let specialQuests = helper.initalizeSpecialQuests()
            let forest = Forest(context: context)
            setupQuests(questList: dailyQuests, contextType: contextType)
            setupQuests(questList: weeklyQuests, contextType: contextType)
            setupQuests(questList: monthlyQuests, contextType: contextType)
            setupQuests(questList: specialQuests, contextType: contextType)
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
                sculpture.mediaLocalPath = sculptureModel.mediaLocalPath
                sculpture.lastUpdatedDate = Date()
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

// MARK: - FETCH HELPERS

extension ForestDataManager {
    
    func fetchSafeForest(contextType: ForestDataManager.ContextType) -> Resource<SafeForestModel> {
        contextType.context.performAndWait {
            let context = contextType.context
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
    
    func fetchForestStatus(contextType: ContextType) -> Resource<ForestStatusModel> {
        contextType.context.performAndWait {
            guard let forest = getCurrentForest(context: contextType.context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            let model = ForestStatusModel(
                rainValue: Int(forest.rainValue),
                landHealthPercentage: Int(forest.landHealthPercent),
                landStatus: forest.landStatus,
                gold: Int(forest.moneyValue)
            )
            return Resource.success(model)
        }
    }
    
    func fetchQuests(contextType: ContextType) -> Resource<[QuestModel]> {
        contextType.context.performAndWait {
            guard let forest = getCurrentForest(context: contextType.context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            var questList: [QuestModel] = []
            if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest] {
                for quest in quests {
                    do {
                        let questModel = try quest.safeObject(context: contextType.context)
                        questList.append(questModel)
                    } catch {
                        print(SafeModelError.invalidMapping.localizedDescription)
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
    
    func claimReward(model: QuestRewardModel, contextType: ContextType) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            
            switch model {
            case .animal(let name):
                let animalModel = createSafeAnimal(assetName: name, contextType: contextType)
                let animal = Animal(context: context)
                animal.id = animalModel.id
                animal.characterName = animalModel.characterName
                animal.createdDate = animalModel.createdDate
                animal.assetName = animalModel.assetName
                animal.healtValue = Int16(animalModel.healthValue)
                animal.isAlive = animalModel.isAlive
                animal.xPosition = animalModel.xPosition
                animal.yPosition = animalModel.yPosition
                animal.mediaLocalPath = animalModel.mediaLocalPath
                animal.lastUpdatedDate = animalModel.lastUpdatedDate
                forest.addToAnimals(animal)
                
            case .plant(let name):
                let treeModel = createSafePlant(assetName: name, contextType: contextType)
                let tree = Tree(context: context)
                tree.id = treeModel.id
                tree.createdDate = treeModel.createdDate
                tree.characterName = treeModel.characterName
                tree.healthValue = Int16(treeModel.treeHealthValue)
                tree.isAlive = treeModel.isAlive
                tree.assetName = treeModel.assetName
                tree.xPosition = treeModel.xPosition
                tree.yPosition = treeModel.yPosition
                tree.mediaLocalPath = treeModel.mediaLocalPath
                tree.lastUpdatedDate = treeModel.lastUpdatedDate
                forest.addToTrees(tree)
                
            case .sculpture(let name):
                let sculptureModel = createSafeSculpture(assetName: name, contextType: contextType)
                let sculpture = Sculpture(context: context)
                sculpture.id = sculptureModel.id
                sculpture.assetName = sculptureModel.assetName
                sculpture.createdDate = sculptureModel.createdDate
                sculpture.characterName = sculptureModel.characterName
                sculpture.xPosition = sculptureModel.xPosition
                sculpture.yPosition = sculptureModel.yPosition
                sculpture.mediaLocalPath = sculptureModel.mediaLocalPath
                sculpture.lastUpdatedDate = sculptureModel.lastUpdatedDate
                forest.addToSculptures(sculpture)
                
            case .gold(let count):
                forest.moneyValue += Int16(count)
                
            case .water(let count):
                forest.rainValue += Int16(count)
                
            case .diamond(let count):
                forest.diamondValue += Int16(count)
            }
            
            forest.lastUpdatedDate = Date()
            
            do {
                try save(context: context)
            } catch {
                return Resource.error(error: error)
            }
            return .success(true)
        }
    }
    
    func overwriteLocalForest(
        with safeForest: SafeForestModel,
        ownerId: String,
        contextType: ContextType
    ) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
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
                tree.mediaLocalPath = treeModel.mediaLocalPath
                newForest.addToTrees(tree)
            }
            
            for animalModel in safeForest.animals {
                let animal = Animal(context: context)
                animal.id = animalModel.id
                animal.assetName = animalModel.assetName
                animal.characterName = animalModel.characterName
                animal.createdDate = animalModel.createdDate
                animal.healtValue = Int16(animalModel.healthValue)
                animal.isAlive = animalModel.isAlive
                animal.lastUpdatedDate = animalModel.lastUpdatedDate
                animal.xPosition = animalModel.xPosition
                animal.yPosition = animalModel.yPosition
                animal.mediaLocalPath = animalModel.mediaLocalPath
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
                sculpture.mediaLocalPath = sculptureModel.mediaLocalPath
                newForest.addToSculptures(sculpture)
            }
            
            for questModel in safeForest.quests {
                let quest = Quest(context: context)
                quest.id = questModel.id
                quest.battleEnemyModel = questModel.battleEnemyModel.valueForCoreData
                quest.currentProgressCount = Int16(questModel.currentProgressCount)
                quest.description_quest = questModel.description
                quest.gameLevel = questModel.gameLevel.valueForCoreData
                quest.lastUpdatedDate = questModel.lastUpdatedDate
                quest.questType = questModel.questionType.valueForCoreData
                quest.rewardType = questModel.reward.typeName
                quest.rewardValue = questModel.reward.coreDataValueString
                quest.status = questModel.status.valueForCoreData
                quest.targetCount = Int16(questModel.targetCount)
                quest.title = questModel.title
                quest.type = questModel.type.valueForCoreData
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
    
    func bindForestToUser(uid: String, contextType: ContextType) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
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
        contextType.context.performAndWait {
            let context = contextType.context
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

    func claimQuestReward(quest: QuestModel, contextType: ContextType) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return .error(error: ForestError.emptyForest)
            }
            if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest], let coreDataQuest = quests.first(where: { $0.id == quest.id }) {
                coreDataQuest.status = QuestStatus.claimed.valueForCoreData
                coreDataQuest.lastUpdatedDate = Date()
            } else {
                return .error(error: ForestError.emptyForest)
            }
            return claimReward(model: quest.reward, contextType: contextType)
        }
    }
    
    func winGame(
        gameLevel: GameLevel,
        battleEnemyMode: BattleEnemyModel,
        gameType: BattleQuestionType,
        contextType: ContextType
    ) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.saveError)
            }
            guard let questList = forest.quests,
                  let quests = questList.allObjects as? [Quest],
                  !quests.isEmpty else {
                return Resource.success(false)
            }
            let targetLevelStr = gameLevel.valueForCoreData
            let targetEnemyStr = battleEnemyMode.valueForCoreData
            let targetTypeStr = gameType.valueForCoreData
            let dailyTypeStr = QuestType.daily.valueForCoreData
            let completedStatusStr = QuestStatus.completed.valueForCoreData
            
            let filteredQuests = quests.filter { quest in
                return quest.gameLevel == targetLevelStr &&
                quest.battleEnemyModel == targetEnemyStr &&
                quest.questType == targetTypeStr &&
                quest.type != dailyTypeStr &&
                quest.status != completedStatusStr
            }
            var hasChanges = false
            for quest in filteredQuests {
                quest.currentProgressCount += 1
                hasChanges = true
                quest.lastUpdatedDate = Date()
                if quest.currentProgressCount >= quest.targetCount {
                    quest.status = completedStatusStr
                }
            }
            if hasChanges {
                do {
                    try save(context: context)
                } catch {
                    return Resource.error(error: ForestError.saveError)
                }
            }
            return Resource.success(true)
        }
    }
    
    func correctAnswer(questionType: BattleQuestionType, contextType: ContextType) -> Resource<Bool>{
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.saveError)
            }
            if let questList = forest.quests, let quests = questList.allObjects as? [Quest] {
                let generalFilteredQuests = quests.filter{ (quest: Quest) in
                    BattleQuestionType
                        .convertFromCoreData(type: quest.questType) == questionType &&
                    QuestType.convertFromCoreData(string: quest.type) == .daily
                }
                for quest in generalFilteredQuests {
                    quest.currentProgressCount += Int16(1)
                    quest.lastUpdatedDate = Date()
                    if quest.currentProgressCount >= quest.targetCount {
                        quest.status = QuestStatus.completed.valueForCoreData
                        quest.currentProgressCount = quest.targetCount
                    }
                }
                do {
                    try save(context: context)
                } catch {
                    return Resource.error(error: ForestError.saveError)
                }
                return Resource.success(true)
            }
            return Resource.error(error: ForestError.emptyList)
        }
    }
    
    func updateRainValue(rain: Int, contextType: ContextType) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.saveError)
            }
            forest.rainValue += Int16(rain)
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
    
    func startRain(contextType: ContextType) -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.saveError)
            }
            forest.rainValue = max(0, forest.rainValue - Int16(ForestConstant.rainValue))
            forest.landStatus = true
            forest.landHealthPercent = Int16(ForestConstant.healthyLandHealth)
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
    
    func updateMoneyValue(money: Int, contextType: ContextType)  -> Resource<Bool> {
        contextType.context.performAndWait {
            let context = contextType.context
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
        contextType.context.performAndWait {
            let context = contextType.context
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
}

// MARK: - POSITION HELPERS

private extension ForestDataManager {
        
    private enum ForestObjectType {
        case tree
        case sculpture
    }
    
    private func generateValidPosition(for type: ForestObjectType, contextType: ContextType) -> (x: Double, y: Double) {
        let xRange = -0.33...0.56
        let yRange = 0.18...0.5
        
        let minDistance: Double = (type == .tree) ? 0.15 : 0.20
        
        let maxAttempts = 100
        
        var existingPositions: [(Double, Double)] = []
        
        if let forest = getCurrentForest(context: contextType.context) {
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
    func createSafeAnimal(assetName: String, contextType _: ContextType) -> AnimalModel {
        return AnimalModel(
            id: UUID(),
            characterName: generateRandomName(type: .animal),
            assetName: assetName,
            createdDate: Date(),
            healthValue: 10,
            isAlive: true,
            xPosition: CGFloat.random(in: -50...50),
            yPosition: CGFloat.random(in: -50...50),
            lastUpdatedDate: Date(),
            mediaLocalPath: resolveMediaLocalPath(for: .animal, assetName: assetName)
        )
    }
    func createSafePlant(assetName: String, contextType: ContextType) -> TreeModel {
        let pos = generateValidPosition(for: .tree, contextType: contextType)
        return TreeModel(
            id: UUID(),
            assetName: assetName,
            characterName: generateRandomName(type: .plant), isAlive: true,
            createdDate: Date(),
            treeHealthValue: 5,
            xPosition: pos.x,
            yPosition: pos.y,
            lastUpdatedDate: Date(),
            mediaLocalPath: resolveMediaLocalPath(for: .plant, assetName: assetName)
        )
    }
    func createSafeSculpture(assetName: String, contextType: ContextType) -> SculptureModel {
        let pos = generateValidPosition(for: .sculpture, contextType: contextType)
        return SculptureModel(
            id: UUID(),
            assetName: assetName,
            characterName: generateRandomName(type: .sculpture), createdDate: Date(),
            xPosition: pos.x,
            yPosition: pos.y,
            lastUpdatedDate: Date(),
            mediaLocalPath: resolveMediaLocalPath(for: .sculpture, assetName: assetName)
        )
    }

    enum RewardMediaCategory: String {
        case animal
        case plant
        case sculpture
    }

    func resolveMediaLocalPath(for category: RewardMediaCategory, assetName: String) -> String? {
        let trimmedAssetName = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAssetName.isEmpty else {
            return nil
        }

        if let descriptor = RewardMediaCatalogStore.descriptor(
            category: category.rawValue,
            modelKey: trimmedAssetName
        ) {
            switch descriptor.sourceType {
            case .localAsset:
                return nil
            case .remoteBundle:
                return ForestLocalMediaPathResolver.resolvePath(for: trimmedAssetName)
            }
        }

        return ForestLocalMediaPathResolver.resolvePath(for: trimmedAssetName)
    }
}
