//
//  ForestDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import CoreData
import UserNotifications

enum ForestError: Error {
    case emptyList
    case emptyForest
    case saveError
    case error(error: Error)
    case emptyUUID
}

// MARK: - CONTEXT ENUM

extension ForestDataManager {
    enum ContextType {
        case main
        case background
        
        var context: NSManagedObjectContext {
            switch self {
            case .main:
                CoreDataManager.shared.viewContext
            case .background:
                CoreDataManager.shared.backgroundContext
            }
        }
    }
}

class ForestDataManager {
    
    // MARK: - PROPERTIES
    
    static let shared = ForestDataManager()
    
    // MARK: - INIT
    
    private init() {}
    
    // MARK: - UPDATE QUESTS
        
    func checkAndResetTimeBasedQuests(helper: ForestGameHelperProtocol, contextType: ContextType) -> Resource<Bool> {
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
    
    func checkGame(contextType: ContextType) {
        checkAndUpdateRain(contextType: contextType)
        checkAndResetTimeBasedQuests(helper: ForestGameHelper(), contextType: contextType)
    }
    
    func checkAndUpdateRain(contextType: ContextType) -> Resource<Bool> {
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
                    return .error(error: ForestError.saveError)
                }
            }
        }
        
        scheduleHealthNotifications(contextType: contextType)
        return .success(true)
    }
    
}

// MARK: - PRIVATE HELPERS

private extension ForestDataManager {
    
    func resetQuests(type: QuestType, helper: ForestGameHelperProtocol, contextType: ContextType) {
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
    
    func scheduleHealthNotifications(contextType: ContextType) {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else { return }
        
        NotificationManager.shared.cancelHealthNotifications()
        
        let currentHealth = Int(forest.landHealthPercent)
        let decayPerHour: Double = 4.0
        
        let targets = [50, 20, 10, 0]
        for target in targets {
            if currentHealth > target {
                let diff = currentHealth - target
                let hoursUntilDrop = Double(diff) / decayPerHour
                let secondsUntilDrop = hoursUntilDrop * 3600
                
                NotificationManager.shared.scheduleHealthNotification(
                    targetValue: target,
                    timeInterval: secondsUntilDrop
                )
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
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else { return }
        for model in questList {
            let quest = Quest(context: context)
            quest.id = model.id
            quest.type = model.type.valueForCoreData
            quest.title = model.title
            quest.description_quest = model.description
            quest.rewardType = model.reward.typeName
            quest.rewardValue = model.reward.valueString
            quest.status = model.status.valueForCoreData
            quest.targetCount = Int16(model.targetCount)
            quest.currentProgressCount = 0
            quest.gameLevel = model.gameLevel.valueForCoreData
            quest.battleEnemyModel = model.battleEnemyModel.valueForCoreData
            quest.questType = model.questionType.valueForCoreData
            forest.addToQuests(quest)
        }
        do {
            try save(context: context)
        } catch {
            print("Setup quest error -> \(error.localizedDescription)")
        }
    }
}

// MARK: - CREATE HELPERS

extension ForestDataManager {
    
    func createForestGame(helper: ForestGameHelperProtocol, contextType: ContextType) -> Resource<Bool> {
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
        forest.rainValue = 0
        forest.isRaining = false
        forest.landHealthPercent = 100
        forest.landStatus = true
        forest.moneyValue = 0
        for sculpture in baseSculptureList {
            createSculpture(sculpture: sculpture, contextType: contextType)
        }
        do {
            try save(context: context)
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }

    func createTree(tree model: TreeModel, contextType: ContextType) -> Resource<Bool>{
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let tree = Tree(context: context)
        tree.id = model.id
        tree.createdDate = Date()
        tree.healthValue = Int16(model.treeHealthValue)
        tree.isAlive = model.isAlive
        tree.assetName = model.assetName
        tree.xPosition = Double(model.xPosition)
        tree.yPosition = Double(model.yPosition)
        forest.addToTrees(tree)
        do {
            try save(context: context)
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
    
    func createAnimal(animal model: AnimalModel, contextType: ContextType) -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let animal = Animal(context: context)
        animal.id = model.id
        animal.createdDate = Date()
        animal.assetName = model.assetName
        animal.healtValue = Int16(model.healthValue)
        animal.isAlive = model.isAlive
        animal.xPosition = Double(model.xPosition)
        animal.yPosition = Double(model.yPosition)
        forest.addToAnimals(animal)
        do {
            try save(context: context)
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
    
    func createSculpture(sculpture model: SculptureModel, contextType: ContextType) -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let sculpture = Sculpture(context: context)
        sculpture.id = model.id
        sculpture.assetName = model.assetName
        sculpture.createdDate = model.createdDate
        sculpture.xPosition = model.xPosition
        sculpture.yPosition = model.yPosition
        forest.addToSculptures(sculpture)
        do {
            try save(context: context)
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
}

// MARK: - FETCH HELPERS

extension ForestDataManager {
    
    func fetchSculpture(id: UUID, contextType: ContextType) -> SculptureModel? {
        let  context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return nil
        }
        if let sculptures = forest.sculptures?.allObjects as? [Sculpture],
               let sculpture = sculptures.first(where: { $0.id == id }) {
            return SculptureModel(
                id: id,
                assetName: sculpture.assetName ?? "",
                characterName: sculpture.characterName ?? "",
                createdDate: sculpture.createdDate ?? Date(),
                xPosition: sculpture.xPosition,
                yPosition: sculpture.yPosition
            )
        }
        return nil
    }
    
    func fetchAnimal(id: UUID, contextType: ContextType) -> AnimalModel? {
        guard let forest = getCurrentForest(context: contextType.context) else {
            return nil
        }
        if let animals = forest.animals?.allObjects as? [Animal],
               let animal = animals.first(where: { $0.id == id }) {
            return AnimalModel(
                id: id,
                characterName: animal.characterName ?? "",
                assetName: animal.assetName ?? "",
                createdDate: animal.createdDate ?? Date(),
                healthValue: Int(animal.healtValue),
                isAlive: animal.isAlive,
                xPosition: animal.xPosition,
                yPosition: animal.yPosition
            )
        }
        return nil
    }
    
    func fetchPlant(id: UUID, contextType: ContextType) -> TreeModel? {
        guard let forest = getCurrentForest(context: contextType.context) else {
            return nil
        }
        if let plants = forest.trees?.allObjects as? [Tree],
               let plant = plants.first(where: { $0.id == id }) {
            do {
                return try plant.safeObject()
            } catch {
                print(SafeModelError.invalidMapping.localizedDescription)
                return nil
            }
        }
        return nil
    }
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest? {
        let request: NSFetchRequest<Forest> = Forest.fetchRequest()
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        }catch {
            return nil
        }
    }
    
    func fetchForestStatus(contextType: ContextType) -> Resource<ForestStatusModel> {
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
    
    func fetchQuests(contextType: ContextType) -> Resource<[QuestModel]> {
        guard let forest = getCurrentForest(context: contextType.context) else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var questList: [QuestModel] = []
        if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest] {
            for quest in quests {
                do {
                    let questModel = try quest.safeObject()
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
    
    func fetchAnimals(contextType: ContextType) -> Resource<[AnimalModel]> {
        guard let forest = getCurrentForest(context: contextType.context) else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var animalList: [AnimalModel] = []
        if let animalSet = forest.animals, let animals = animalSet.allObjects as? [Animal]  {
            for animal in animals {
                do {
                    let animalModel = try animal.safeObject()
                    animalList.append(animalModel)
                } catch {
                    print(SafeModelError.invalidMapping.localizedDescription)
                    return Resource.error(error: SafeModelError.invalidMapping)
                }
            }
            return Resource.success(animalList)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func fetchTrees(contextType: ContextType) -> Resource<[TreeModel]> {
        guard let forest = getCurrentForest(context: contextType.context) else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var treeList: [TreeModel] = []
        if let treeSet = forest.trees, let trees = treeSet.allObjects as? [Tree]  {
            for tree in trees {
                do {
                    let treeModel = try tree.safeObject()
                    treeList.append(treeModel)
                } catch {
                    print(SafeModelError.invalidMapping.localizedDescription)
                    return Resource.error(error: SafeModelError.invalidMapping)
                }
            }
            return Resource.success(treeList)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func fetchSculptures(contextType: ContextType) -> Resource<[SculptureModel]> {
        guard let forest = getCurrentForest(context: contextType.context) else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var sculptureList: [SculptureModel] = []
        if let sculptureSet = forest.sculptures, let sculptures = sculptureSet.allObjects as? [Sculpture]  {
            for sculpture in sculptures {
                do {
                    let sculptureModel = try sculpture.safeObject()
                    sculptureList.append(sculptureModel)
                } catch {
                    print(SafeModelError.invalidMapping.localizedDescription)
                    return Resource.error(error: SafeModelError.invalidMapping)
                }
            }
            return Resource.success(sculptureList)
        }
        return Resource.error(error: ForestError.emptyList)
    }
}

// MARK: - UPDATE HELPERS

extension ForestDataManager {
    func claimReward(quest: QuestModel, contextType: ContextType) -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return .error(error: ForestError.emptyForest)
        }
        if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest], let coreDataQuest = quests.first(where: { $0.id == quest.id }) {
            coreDataQuest.status = QuestStatus.claimed.valueForCoreData
            do {
                try save(context: context)
                return Resource.success(nil)
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
        } else {
            return .error(error: ForestError.emptyForest)
        }
        
        switch quest.reward {
        case .animal(let name):
            let animalModel = AnimalModel(
                id: UUID(),
                characterName: generateRandomName(type: .animal),
                assetName: name,
                createdDate: Date(),
                healthValue: 10,
                isAlive: true,
                xPosition: CGFloat.random(in: -50...50),
                yPosition: CGFloat.random(in: -50...50)
            )
            createAnimal(animal: animalModel, contextType: contextType)
            
        case .plant(let name):
            let pos = generateValidPosition(for: .tree, contextType: contextType)
            let plantModel = TreeModel(
                id: UUID(),
                assetName: name,
                characterName: generateRandomName(type: .plant), isAlive: true,
                createdDate: Date(),
                treeHealthValue: 5,
                xPosition: pos.x,
                yPosition: pos.y
            )
            createTree(tree: plantModel, contextType: contextType)
            
        case .gold(let count):
            updateMoneyValue(money: count, contextType: contextType)
            
        case .water(let count):
            updateRainValue(rain: count, contextType: contextType)
            
        case .sculpture(let name):
            let pos = generateValidPosition(for: .sculpture, contextType: contextType)
            let sculptureModel = SculptureModel(
                id: UUID(),
                assetName: name,
                characterName: generateRandomName(type: .sculpture), createdDate: Date(),
                xPosition: pos.x,
                yPosition: pos.y
            )
            createSculpture(sculpture: sculptureModel, contextType: contextType)
        }
        do {
            try save(context: context)
        }
        catch {
            return Resource.error(error: error)
        }
        return .success(true)
    }
    
    func winGame(
        gameLevel: GameLevel,
        battleEnemyMode: BattleEnemyModel,
        gameType: BattleQuestionType,
        contextType: ContextType
    ) -> Resource<Bool> {
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
    
    func correctAnswer(questionType: BattleQuestionType, contextType: ContextType) -> Resource<Bool>{
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
    
    func updateComponentPosition(
        model: ComponentModelProtocol,
        xValue: CGFloat,
        yValue: CGFloat,
        contextType: ContextType
    ) -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return .error(error: ForestError.emptyForest)
        }
        var isFound = false
        switch model.type {
        case .animal:
            if let animals = forest.animals?.allObjects as? [Animal],
               let target = animals.first(where: { $0.id == model.id }) {
                target.xPosition = xValue
                target.yPosition = yValue
                isFound = true
            }
            
        case .plant:
            if let trees = forest.trees?.allObjects as? [Tree],
               let target = trees.first(where: { $0.id == model.id }) {
                target.xPosition = xValue
                target.yPosition = yValue
                isFound = true
            }
            
        case .sculpture:
            if let sculptures = forest.sculptures?.allObjects as? [Sculpture],
               let target = sculptures.first(where: { $0.id == model.id }) {
                target.xPosition = xValue
                target.yPosition = yValue
                isFound = true
            }
        default:
            break
        }
        if isFound {
            do {
                try save(context: context)
                return .success(true)
            } catch {
                return .error(error: ForestError.saveError)
            }
        }
        return .error(error: ForestError.emptyUUID)
    }
    
    func updateComponentName(id: UUID, type: ComponentType, newName: String, contextType: ContextType) -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return .error(error: ForestError.emptyForest)
        }
        var isFound = false
        switch type {
        case .animal:
            if let animals = forest.animals?.allObjects as? [Animal],
               let target = animals.first(where: { $0.id == id }) {
                target.characterName = newName
                isFound = true
            }
            
        case .plant:
            if let trees = forest.trees?.allObjects as? [Tree],
               let target = trees.first(where: { $0.id == id }) {
                target.characterName = newName
                isFound = true
            }
            
        case .sculpture:
            if let sculptures = forest.sculptures?.allObjects as? [Sculpture],
               let target = sculptures.first(where: { $0.id == id }) {
                target.characterName = newName
                isFound = true
            }
        default:
            break
        }
        if isFound {
            do {
                try save(context: context)
                return .success(true)
            } catch {
                return .error(error: ForestError.saveError)
            }
        }
        return .error(error: ForestError.emptyUUID)
    }
    
    func updateRainValue(rain: Int, contextType: ContextType) -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return Resource.error(error: ForestError.saveError)
        }
        forest.rainValue += Int16(rain)
        do {
            try save(context: context)
        }
        catch {
            return Resource.error(error: error)
        }
        return Resource.success(true)
    }
    
    func startRain(contextType: ContextType) -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return Resource.error(error: ForestError.saveError)
        }
        forest.rainValue -= Int16(ForestConstant.rainValue)
        forest.landStatus = true
        forest.landHealthPercent = Int16(ForestConstant.healthyLandHealth)
        do {
            try save(context: context)
        }
        catch {
            return Resource.error(error: error)
        }
        return Resource.success(true)
    }
    
    func updateMoneyValue(money: Int, contextType: ContextType)  -> Resource<Bool> {
        let context = contextType.context
        guard let forest = getCurrentForest(context: context) else {
            return Resource.error(error: ForestError.saveError)
        }
        forest.moneyValue += Int16(money)
        do {
            try save(context: context)
        }
        catch {
            return Resource.error(error: error)
        }
        return Resource.success(true)
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
