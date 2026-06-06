//
//  ForestEntityService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.05.2026.
//

import Foundation
import CoreData

protocol ForestEntityServiceProtocol: AnyObject {
    func createTree(tree model: TreeModel, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func createAnimal(animal model: AnimalModel, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    func createSculpture(sculpture model: SculptureModel, contextType: ForestDataManager.ContextType) -> Resource<Bool>
    
    func fetchSculpture(id: UUID, contextType: ForestDataManager.ContextType) -> SculptureModel?
    func fetchAnimal(id: UUID, contextType: ForestDataManager.ContextType) -> AnimalModel?
    func fetchPlant(id: UUID, contextType: ForestDataManager.ContextType) -> TreeModel?
    func fetchAnimals(contextType: ForestDataManager.ContextType) -> Resource<[AnimalModel]>
    func fetchTrees(contextType: ForestDataManager.ContextType) -> Resource<[TreeModel]>
    func fetchSculptures(contextType: ForestDataManager.ContextType) -> Resource<[SculptureModel]>
    
    func updateComponentPosition(
        model: ComponentModelProtocol,
        xValue: CGFloat,
        yValue: CGFloat,
        contextType: ForestDataManager.ContextType
    ) -> Resource<Bool>
    
    func updateComponentName(
        id: UUID,
        type: ComponentType,
        newName: String,
        contextType: ForestDataManager.ContextType
    ) -> Resource<Bool>
}

final class ForestEntityServiceAdapter: ForestEntityServiceProtocol {
    private let coreDataManager: CoreDataManagerProtocol
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
    }
    
    func createTree(tree model: TreeModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            let tree = Tree(context: context)
            tree.id = model.id
            tree.createdDate = Date()
            tree.characterName = generateRandomName(type: .plant)
            tree.healthValue = Int16(model.treeHealthValue)
            tree.isAlive = model.isAlive
            tree.assetName = model.assetName
            tree.assetSourceString = model.assetSource.rawValue
            tree.posterKey = model.poster.key
            tree.posterSourceString = model.poster.source.rawValue
            tree.xPosition = Double(model.xPosition)
            tree.yPosition = Double(model.yPosition)
            tree.lastUpdatedDate = Date()
            forest.addToTrees(tree)
            do {
                try save(context: context)
                return Resource.success(true)
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
        }
    }

    func createAnimal(animal model: AnimalModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            let animal = Animal(context: context)
            animal.id = model.id
            animal.characterName = generateRandomName(type: .animal)
            animal.createdDate = Date()
            animal.assetName = model.assetName
            animal.assetSourceString = model.assetSource.rawValue
            animal.posterKey = model.poster.key
            animal.posterSourceString = model.poster.source.rawValue
            animal.healtValue = Int16(model.healthValue)
            animal.isAlive = model.isAlive
            animal.xPosition = Double(model.xPosition)
            animal.yPosition = Double(model.yPosition)
            animal.lastUpdatedDate = Date()
            forest.addToAnimals(animal)
            do {
                try save(context: context)
                return Resource.success(true)
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
        }
    }

    func createSculpture(sculpture model: SculptureModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            let sculpture = Sculpture(context: context)
            sculpture.id = model.id
            sculpture.assetName = model.assetName
            sculpture.assetSourceString = model.assetSource.rawValue
            sculpture.posterKey = model.poster.key
            sculpture.posterSourceString = model.poster.source.rawValue
            sculpture.createdDate = model.createdDate
            sculpture.characterName = generateRandomName(type: .sculpture)
            sculpture.xPosition = Double(model.xPosition)
            sculpture.yPosition = Double(model.yPosition)
            sculpture.lastUpdatedDate = Date()
            forest.addToSculptures(sculpture)
            do {
                try save(context: context)
                return Resource.success(true)
            } catch {
                return Resource.error(error: ForestError.saveError)
            }
        }
    }
    
    func fetchSculpture(id: UUID, contextType: ForestDataManager.ContextType) -> SculptureModel? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return nil
            }
            if let sculptures = forest.sculptures?.allObjects as? [Sculpture],
               let sculpture = sculptures.first(where: { $0.id == id }){
                return try? sculpture.safeObject(context: context)
            }
            return nil
        }
    }
    
    func fetchAnimal(id: UUID, contextType: ForestDataManager.ContextType) -> AnimalModel? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return nil
            }
            if let animals = forest.animals?.allObjects as? [Animal],
               let animal = animals.first(where: { $0.id == id }){
                return try? animal.safeObject(context: context)
            }
            return nil
        }
    }
    
    func fetchPlant(id: UUID, contextType: ForestDataManager.ContextType) -> TreeModel? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return nil
            }
            if let plants = forest.trees?.allObjects as? [Tree],
               let plant = plants.first(where: { $0.id == id }) {
                return try? plant.safeObject(context: context)
            }
            return nil
        }
    }
    
    func fetchAnimals(contextType: ForestDataManager.ContextType) -> Resource<[AnimalModel]> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            var animalList: [AnimalModel] = []
            if let animalSet = forest.animals, let animals = animalSet.allObjects as? [Animal] {
                for animal in animals {
                    do {
                        let animalModel = try animal.safeObject(context: context)
                        animalList.append(animalModel)
                    } catch {
                        return Resource.error(error: SafeModelError.invalidMapping)
                    }
                }
                return Resource.success(animalList)
            }
            return Resource.error(error: ForestError.emptyList)
        }
    }
    
    func fetchTrees(contextType: ForestDataManager.ContextType) -> Resource<[TreeModel]> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            var treeList: [TreeModel] = []
            if let treeSet = forest.trees, let trees = treeSet.allObjects as? [Tree] {
                for tree in trees {
                    do {
                        let treeModel = try tree.safeObject(context: context)
                        treeList.append(treeModel)
                    } catch {
                        return Resource.error(error: SafeModelError.invalidMapping)
                    }
                }
                return Resource.success(treeList)
            }
            return Resource.error(error: ForestError.emptyList)
        }
    }
    
    func fetchSculptures(contextType: ForestDataManager.ContextType) -> Resource<[SculptureModel]> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return Resource.error(error: ForestError.emptyForest)
            }
            var sculptureList: [SculptureModel] = []
            if let sculptureSet = forest.sculptures, let sculptures = sculptureSet.allObjects as? [Sculpture] {
                for sculpture in sculptures {
                    do {
                        let sculptureModel = try sculpture.safeObject(context: context)
                        sculptureList.append(sculptureModel)
                    } catch {
                        return Resource.error(error: SafeModelError.invalidMapping)
                    }
                }
                return Resource.success(sculptureList)
            }
            return Resource.error(error: ForestError.emptyList)
        }
    }
    
    func updateComponentPosition(
        model: ComponentModelProtocol,
        xValue: CGFloat,
        yValue: CGFloat,
        contextType: ForestDataManager.ContextType
    ) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
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
                    target.lastUpdatedDate = Date()
                    isFound = true
                }
            case .plant:
                if let trees = forest.trees?.allObjects as? [Tree],
                   let target = trees.first(where: { $0.id == model.id }) {
                    target.xPosition = xValue
                    target.yPosition = yValue
                    target.lastUpdatedDate = Date()
                    isFound = true
                }
            case .sculpture:
                if let sculptures = forest.sculptures?.allObjects as? [Sculpture],
                   let target = sculptures.first(where: { $0.id == model.id }) {
                    target.xPosition = xValue
                    target.yPosition = yValue
                    target.lastUpdatedDate = Date()
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
    }
    
    func updateComponentName(
        id: UUID,
        type: ComponentType,
        newName: String,
        contextType: ForestDataManager.ContextType
    ) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let forest = getCurrentForest(context: context) else {
                return .error(error: ForestError.emptyForest)
            }
            var isFound = false
            switch type {
            case .animal:
                if let animals = forest.animals?.allObjects as? [Animal],
                   let target = animals.first(where: { $0.id == id }) {
                    target.characterName = newName
                    target.lastUpdatedDate = Date()
                    isFound = true
                }
            case .plant:
                if let trees = forest.trees?.allObjects as? [Tree],
                   let target = trees.first(where: { $0.id == id }) {
                    target.characterName = newName
                    target.lastUpdatedDate = Date()
                    isFound = true
                }
            case .sculpture:
                if let sculptures = forest.sculptures?.allObjects as? [Sculpture],
                   let target = sculptures.first(where: { $0.id == id }) {
                    target.characterName = newName
                    target.lastUpdatedDate = Date()
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
    }
}

private extension ForestEntityServiceAdapter {
    func getContext(for type: ForestDataManager.ContextType) -> NSManagedObjectContext {
        switch type {
        case .main:
            return coreDataManager.viewContext
        case .background:
            return coreDataManager.backgroundContext
        }
    }
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest? {
        let request: NSFetchRequest<Forest> = Forest.fetchRequest()
        request.fetchLimit = 1
        do {
            return try context.performAndWait {
                try context.fetch(request).first
            }
        } catch {
            return nil
        }
    }
    
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw error
        }
    }
}
