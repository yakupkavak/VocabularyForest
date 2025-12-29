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

class ForestDataManager {
    
    // MARK: - PROPERTIES
    
    static let shared = ForestDataManager()
    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "VocabularyForest")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Core data couldn't inin -> \(error.localizedDescription)")
            }
        }
        viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - HELPERS
    
    func checkAndUpdateRain() -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return .error(error: ForestError.emptyForest)
        }
        
        let now = Date()
        
        guard let lastUpdate = forest.lastRainUpdateDate else {
            forest.lastRainUpdateDate = now
            try? save()
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
                    try save()
                    scheduleHealthNotifications()
                } catch {
                    return .error(error: ForestError.saveError)
                }
            }
        }
        
        scheduleHealthNotifications()
        return .success(true)
    }
    
    private func scheduleHealthNotifications() {
        guard let forest = getCurrentForest() else { return }
        
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
    
    private func save() throws {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Core data couldn't saved -> \(error.localizedDescription)")
            throw error
        }
    }
    
    func getCurrentForest() -> Forest? {
        let request: NSFetchRequest<Forest> = Forest.fetchRequest()
        request.fetchLimit = 1
        do {
            return try viewContext.fetch(request).first
        }catch {
            return nil
        }
    }
    
    // MARK: - CREATE FOREST
    
    func createForestGame(helper: ForestGameHelperProtocol) -> Resource<Bool> {
        let dailyQuests = helper.initalizeDailyQuests()
        let weeklyQuests = helper.initalizeWeeklyQuests()
        let monthlyQuests = helper.initalizeMonthlyQuests()
        let specialQuests = helper.initalizeSpecialQuests()
        let forest = Forest(context: viewContext)
        setupQuests(questList: dailyQuests, forest: forest)
        setupQuests(questList: weeklyQuests, forest: forest)
        setupQuests(questList: monthlyQuests, forest: forest)
        setupQuests(questList: specialQuests, forest: forest)
        forest.rainValue = 0
        forest.isRaining = false
        forest.landHealthPercent = 100
        forest.landStatus = true
        forest.moneyValue = 0
        for sculpture in baseSculptureList {
            createSculpture(sculpture: sculpture)
        }
        do {
            try save()
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
    
    private func setupQuests(questList: [QuestModel], forest: Forest) {
        for model in questList {
            let quest = Quest(context: viewContext)
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
            try save()
        }catch {
            print(error.localizedDescription)
        }
    }
    
    func createTree(tree model: TreeModel) -> Resource<Bool>{
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let tree = Tree(context: viewContext)
        tree.id = model.id
        tree.createdDate = Date()
        tree.healthValue = Int16(model.treeHealthValue)
        tree.isAlive = model.isAlive
        tree.name = model.treeName
        tree.xPosition = Double(model.treeXPosition)
        tree.yPosition = Double(model.treeYPosition)
        forest.addToTrees(tree)
        do {
            try save()
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
    
    func createAnimal(animal model: AnimalModel) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let animal = Animal(context: viewContext)
        animal.id = model.id
        animal.createdDate = Date()
        animal.assetName = model.assetName
        animal.healtValue = Int16(model.healthValue)
        animal.isAlive = model.isAlive
        animal.name = model.name
        animal.xPosition = Double(model.xPosition)
        animal.yPosition = Double(model.yPosition)
        forest.addToAnimals(animal)
        do {
            try save()
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
    
    func createSculpture(sculpture model: SculptureModel) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let sculpture = Sculpture(context: viewContext)
        sculpture.id = model.id
        sculpture.name = model.name
        sculpture.createdDate = model.createDate
        sculpture.xPosition = model.xPosition
        sculpture.yPosition = model.yPosition
        forest.addToSculptures(sculpture)
        do {
            try save()
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
    
    // MARK: - QUESTS
    
    func refreshDailyQuests(helper: ForestGameHelperProtocol) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        if let currentQuests = forest.quests?.allObjects as? [Quest] {
            let oldDailyQuests = currentQuests.filter {
                $0.type == QuestType.daily.valueForCoreData
            }
            for oldQuest in oldDailyQuests {
                viewContext.delete(oldQuest)
            }
        }
        let newQuestsModels = helper.initalizeDailyQuests()
        setupQuests(questList: newQuestsModels, forest: forest)
        do {
            try save()
            return Resource.success(true)
        } catch {
            return Resource.error(error: error)
        }
    }
    
    // MARK: - FETCH HELPERS
    
    func fetchForestStatus() -> Resource<ForestStatusModel> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let model = ForestStatusModel(rainValue: Int(forest.rainValue), landHealthPercentage: Int(forest.landHealthPercent), landStatus: forest.landStatus, gold: Int(forest.moneyValue))
        return Resource.success(model)
    }
    
    func fetchQuests() -> Resource<[QuestModel]> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var questList: [QuestModel] = []
        if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest] {
            for quest in quests {
                if let id = quest.id {
                    let model = QuestModel.convertModel(quest: quest, id: id)
                    questList.append(model)
                } else {
                    continue
                }
            }
        }
        if questList.isEmpty {
            return Resource.error(error: ForestError.emptyList)
        }else {
            return Resource.success(questList)
        }
    }
    
    func fetchAnimals() -> Resource<[AnimalModel]> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var animalList: [AnimalModel] = []
        if let animalSet = forest.animals, let animals = animalSet.allObjects as? [Animal]  {
            for animal in animals {
                guard let id = animal.id else {
                    return Resource.error(error: ForestError.emptyUUID)
                }
                let animalModel = AnimalModel(
                    id: id,
                    name: animal.name ?? "",
                    assetName: animal.assetName ?? "Cat",
                    createdDate: animal.createdDate ?? Date(),
                    healthValue: Int(animal.healtValue),
                    isAlive: animal.isAlive,
                    xPosition: CGFloat(animal.xPosition),
                    yPosition: CGFloat(animal.yPosition)
                )
                animalList.append(animalModel)
            }
            
            return Resource.success(animalList)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func fetchTrees() -> Resource<[TreeModel]> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var sculptureList: [TreeModel] = []
        if let treeSet = forest.trees, let trees = treeSet.allObjects as? [Tree]  {
            for tree in trees {
                guard let id = tree.id else {
                    return Resource.error(error: ForestError.emptyUUID)
                }
                let model = TreeModel(
                    id: id,
                    treeName: tree.name ?? "grass_sculpure",
                    isAlive: tree.isAlive,
                    createdDate: tree.createdDate ?? Date(),
                    treeHealthValue: Int(tree.healthValue),
                    treeXPosition: tree.xPosition,
                    treeYPosition: tree.yPosition,
                )
                sculptureList.append(model)
            }
            return Resource.success(sculptureList)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func fetchSculptures() -> Resource<[SculptureModel]> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        var sculptureList: [SculptureModel] = []
        if let sculptureSet = forest.sculptures, let sculptures = sculptureSet.allObjects as? [Sculpture]  {
            for sculpture in sculptures {
                guard let id = sculpture.id else { return Resource.error(error: ForestError.emptyUUID) }
                let model = SculptureModel(
                    id: id,
                    name: sculpture.name ?? "grass_sculpure",
                    createDate: sculpture.createdDate ?? Date(),
                    xPosition: sculpture.xPosition,
                    yPosition: sculpture.yPosition
                )
                sculptureList.append(model)
            }
            return Resource.success(sculptureList)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    // MARK: - UPDATE
    
    func claimReward(quest: QuestModel) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return .error(error: ForestError.emptyForest)
        }        
        if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest], let coreDataQuest = quests.first(where: { $0.id == quest.id }) {
            coreDataQuest.status = QuestStatus.claimed.valueForCoreData
            do {
                try save()
            } catch {
                print(error.localizedDescription)
            }
        } else {
            return .error(error: ForestError.emptyForest)
        }
        
        switch quest.reward {
        case .animal(let name):
            let animalModel = AnimalModel(
                id: UUID(),
                name: "\(name)",
                assetName: name,
                createdDate: Date(),
                healthValue: 10,
                isAlive: true,
                xPosition: CGFloat.random(in: -50...50),
                yPosition: CGFloat.random(in: -50...50)
            )
            createAnimal(animal: animalModel)
            
        case .plant(let name):
            let pos = generateValidPosition(for: .tree)
            
            let plantModel = TreeModel(
                id: UUID(),
                treeName: name,
                isAlive: true,
                createdDate: Date(),
                treeHealthValue: 5,
                treeXPosition: pos.x,
                treeYPosition: pos.y
            )
            createTree(tree: plantModel)
            
        case .gold(let count):
            updateMoneyValue(money: count)
            
        case .water(let count):
            updateRainValue(rain: count)
            
        case .sculpture(let name):
            let pos = generateValidPosition(for: .sculpture)
            
            let sculptureModel = SculptureModel(
                id: UUID(),
                name: name,
                createDate: Date(),
                xPosition: pos.x,
                yPosition: pos.y
            )
            createSculpture(sculpture: sculptureModel)
        }
        
        return .success(true)
    }
    
    func winGame(gameLevel: GameLevel, battleEnemyMode: BattleEnemyModel, gameType: BattleQuestionType) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
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
                try save()
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
        }
        return Resource.success(true)
    }
    
    func correctAnswer(questionType: BattleQuestionType,) -> Resource<Bool>{
        guard let forest = getCurrentForest() else {
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
                try save()
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
            return Resource.success(true)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func updateForestStatus(model: ForestStatusModel) {
        
    }
    
    func updateRainValue(rain: Int) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.saveError)
        }
        forest.rainValue += Int16(rain)
        return Resource.success(true)
    }
    func updateMoneyValue(money: Int)  -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.saveError)
        }
        forest.moneyValue += Int16(money)
        return Resource.success(true)
    }
}

private extension ForestDataManager {
    // MARK: - POSITION GENERATOR
    
    private enum ForestObjectType {
        case tree
        case sculpture
    }
    
    private func generateValidPosition(for type: ForestObjectType) -> (x: Double, y: Double) {
        let xRange = -0.33...0.6
        let yRange = 0.2...0.4
        
        let minDistance: Double = (type == .tree) ? 0.05 : 0.1
        let maxAttempts = 50
        var existingPositions: [(Double, Double)] = []
        
        if let forest = getCurrentForest() {
            if type == .tree {
                if let trees = forest.trees?.allObjects as? [Tree] {
                    existingPositions = trees.map { ($0.xPosition, $0.yPosition) }
                }
            } else {
                if let sculptures = forest.sculptures?.allObjects as? [Sculpture] {
                    existingPositions = sculptures.map { ($0.xPosition, $0.yPosition) }
                }
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
