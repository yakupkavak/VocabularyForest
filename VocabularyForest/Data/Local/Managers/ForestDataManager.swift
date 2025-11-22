//
//  ForestDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import CoreData

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
            return Resource.success(data: nil)
        } catch {
            return Resource.error(error: error)
        }
    }
    
    func createTree(tree model: TreeModel) -> Resource<Bool>{
        guard let forest = getCurrentForest() else {
            return Resource.error(error: nil)
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
            return Resource.success(data: nil)
        } catch {
            return Resource.error(error: error)
        }
    }
    
    func createAnimal(animal model: Animal) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: nil)
        }
        let animal = Animal(context: viewContext)
        animal.createdDate = Date()
        animal.healtValue = Int16(model.healtValue)
        animal.isAlive = model.isAlive
        animal.name = model.name
        animal.xPosition = Double(model.xPosition)
        animal.yPosition = Double(model.yPosition)
        forest.addToAnimals(animal)
        do {
           try save()
            return Resource.success(data: nil)
        } catch {
            return Resource.error(error: error)
        }
    }
    
    func createSculpture(sculpture model: SculptureModel) -> Resource<Bool> {
        guard let forest = getCurrentForest() else {
            return Resource.error(error: nil)
        }
        let sculpture = Sculpture(context: viewContext)
        sculpture.name = model.name
        sculpture.createdDate = model.createDate
        sculpture.xPosition = model.xPosition
        sculpture.yPosition = model.yPosition
        forest.addToSculptures(sculpture)
        do {
           try save()
            return Resource.success(data: nil)
        } catch {
            return Resource.error(error: error)
        }
    }
    
    func fetchForestStatus() -> ForestStatusModel {
        ForestStatusModel(rainPercentage: 1, landHealthPercentage: 1, landStatus: false)
    }
    
    func updateForestStatus(model: ForestStatusModel) {
        
    }
}
