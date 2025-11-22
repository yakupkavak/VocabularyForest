//
//  ForestDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import CoreData

enum ForestError: Error {
    case emptyList
    case emptyForest
    case saveError
    case error(error: Error)
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
    
    // MARK: - PRIVATE HELPERS
    
    private func save() throws {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Core data couldn't saved -> \(error.localizedDescription)")
            throw error
        }
    }
    
    private func getCurrentForest() -> Forest? {
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
        let quests = helper.initalizeQuests()
        let forest = Forest(context: viewContext)
        forest.rainValue = 0
        forest.isRaining = false
        forest.landHealthPercent = 100
        forest.landStatus = true
        for model in quests {
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
            forest.addToQuests(quest)
        }
        do {
            try save()
            return Resource.success(nil)
        } catch {
            return Resource.error(error: ForestError.saveError)
        }
    }
    
    func createTree(tree model: TreeModel) -> Resource<Bool>{
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        let tree = Tree(context: viewContext)
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
        animal.createdDate = Date()
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
        let newQuestsModels = helper.initalizeQuests()
        let newDailyModels = newQuestsModels.filter { $0.type == .daily }
        for model in newDailyModels {
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
            quest.forest = forest
        }
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
        let model = ForestStatusModel(rainValue: Int(forest.rainValue), landHealthPercentage: Int(forest.landHealthPercent), landStatus: forest.landStatus)
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
                    let model = QuestModel(id: id, type: QuestType.convertFromCoreData(string: quest.type), title: quest.title ?? "", description: quest.description_quest ?? "", reward: .convertFromCoreData(type: quest.rewardType, value: quest.rewardValue), status: .convertFromCoreData(string: quest.status), targetCount: Int(quest.targetCount), currentProgressCount: Int(quest.currentProgressCount))
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
    
    func fetchAnimals() -> Resource<[Animal]> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        if let animalSet = forest.animals, let animals = animalSet.allObjects as? [Animal]  {
            return Resource.success(animals)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func fetchTrees() -> Resource<[Tree]> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        if let treeSet = forest.trees, let trees = treeSet.allObjects as? [Tree]  {
            return Resource.success(trees)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func fetchSculptures() -> Resource<[Sculpture]> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: ForestError.emptyForest)
        }
        if let sculptureSet = forest.sculptures, let sculptures = sculptureSet.allObjects as? [Sculpture]  {
            return Resource.success(sculptures)
        }
        return Resource.error(error: ForestError.emptyList)
    }
    
    func updateForestStatus(model: ForestStatusModel) {
        
    }
}
