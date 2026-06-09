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
    case alreadyExistQuest
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
    func checkAndUpdateRain(contextType: ForestDataManager.ContextType) -> Resource<Bool>
    
    // MARK: Create Helpers
    
    func createForest(contextType: ForestDataManager.ContextType) -> Resource<Forest>
    
    // MARK: Fetch Helpers
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest?
    func fetchForestStatus(contextType: ForestDataManager.ContextType) -> Resource<ForestStatusModel>
    func fetchSafeForest(contextType: ForestDataManager.ContextType) -> Resource<SafeForestModel>
    
    // MARK: - QUEST HELPERS
    
    func fetchQuestTracks(contextType: ForestDataManager.ContextType) -> Resource<[QuestTrackModel]>
    func fetchQuestTrack(id: String, contextType: ForestDataManager.ContextType) -> Resource<QuestTrackModel>
    func importQuest(track: QuestTrackModel, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateQuest(questTrack: QuestTrackModel, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    
    // MARK: Update Helpers
    
    func overwriteLocalForest(with safeForest: SafeForestModel, ownerId: String, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func bindForestToUser(uid: String, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateLastSyncCloudTime(date: Date, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateRainValue(rain: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func startRain(contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateMoneyValue(money: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func updateDiamondValue(diamond: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func claimReward(model: ReadyRewardModel, contextType: ForestDataManager.ContextType) throws
}

class ForestDataManager: ForestDataManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private let coreDataManager: CoreDataManagerProtocol
    weak var notificationManager: (any NotificationManagerProtocol)?
    
    // MARK: - INIT
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
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
        checkAndUpdateRain(contextType: contextType)
        //checkAndResetTimeBasedQuests(helper: ForestGameHelper(), contextType: contextType)
    }
    
    func checkAndUpdateRain(contextType: ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
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
    func importQuest(track: QuestTrackModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest], let _ = quests.first(where: { $0.id == track.id }) {
                return Resource.error(error: ForestError.alreadyExistQuest)
            } else {
                let quest = Quest(context: context)
                quest.currentProgressCount = Int16(track.currentProgressCount)
                quest.id = track.id
                quest.status = track.status.valueForCoreData
                quest.lastUpdatedDate = track.lastUpdatedDate
                forest.addToQuests(quest)
                do {
                    try save(context: context)
                    return .success(true)
                } catch {
                    return .error(error: ForestError.saveError)
                }
            }
        }
    }
}

// MARK: - FETCH HELPERS

extension ForestDataManager {
    
    func fetchQuestTrack(id: String, contextType: ForestDataManager.ContextType) -> Resource<QuestTrackModel> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            if let questSet = forest.quests, let quests = questSet.allObjects as? [Quest], let coreDataQuest = quests.first(where: { $0.id == id }) {
                do {
                    let questTrack = try coreDataQuest.safeObject(context: context)
                    return Resource.success(questTrack)
                }catch {
                    print("\(error.localizedDescription)")
                    return .error(error: error)
                }
            } else {
                return .error(error: ForestError.emptyForest)
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
    
    func fetchForestStatus(contextType: ContextType) -> Resource<ForestStatusModel> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
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
                animal.healtValue = Int16(animalModel.healthValue)
                animal.isAlive = animalModel.isAlive
                animal.xPosition = animalModel.xPosition
                animal.yPosition = animalModel.yPosition
                animal.lastUpdatedDate = animalModel.lastUpdatedDate
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
                tree.lastUpdatedDate = treeModel.lastUpdatedDate
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
                newForest.addToSculptures(sculpture)
            }
            
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
    
    func bindForestToUser(uid: String, contextType: ContextType) -> Resource<Bool> {
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
    
    func updateQuest(questTrack: QuestTrackModel, contextType: ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        guard let forest = getCurrentForest(context: context) else {
            return Resource.error(error: ForestError.saveError)
        }
        return context.performAndWait {
            if let questList = forest.quests, let quests = questList.allObjects as? [Quest] {
                guard let quest = quests.first(where: { $0.id == questTrack.id }) else { return Resource.error(error: nil)
                }
                quest.currentProgressCount = Int16(questTrack.currentProgressCount)
                quest.status = questTrack.status.valueForCoreData
                quest.lastUpdatedDate = questTrack.lastUpdatedDate
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
        let context = getContext(for: contextType)
        return context.performAndWait {
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
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.saveError)
            }
            forest.rainValue -= Int16(ForestConstant.rainValue)
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
}

// MARK: - PRIVATE HELPERS

private extension ForestDataManager {
    
    private func getContext(for type: ContextType) -> NSManagedObjectContext {
        switch type {
        case .main:
            return coreDataManager.viewContext
        case .background:
            return coreDataManager.backgroundContext
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
            print("Core data couldn't saved -> \(error.localizedDescription)")
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
                print("Setup quest error -> \(error.localizedDescription)")
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
            lastUpdatedDate: Date()
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
            lastUpdatedDate: Date()
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
            lastUpdatedDate: Date()
        )
    }
}
