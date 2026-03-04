//
//  Forest+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//
//

public import Foundation
public import CoreData


public typealias ForestCoreDataPropertiesSet = NSSet

extension Forest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Forest> {
        return NSFetchRequest<Forest>(entityName: "Forest")
    }

    @NSManaged public var rainValue: Int16
    @NSManaged public var moneyValue: Int16
    @NSManaged public var landHealthPercent: Int16
    @NSManaged public var landStatus: Bool
    @NSManaged public var isRaining: Bool
    @NSManaged public var lastRainUpdateDate: Date?
    @NSManaged public var lastDailyResetDate: Date?
    @NSManaged public var lastWeeklyResetDate: Date?
    @NSManaged public var lastMonthlyResetDate: Date?
    @NSManaged public var quests: NSSet?
    @NSManaged public var sculptures: NSSet?
    @NSManaged public var trees: NSSet?
    @NSManaged public var animals: NSSet?

}

extension Forest: ConvertSafeModel {
    typealias SafeModel = SafeForestModel
    func safeObject(context: NSManagedObjectContext) throws -> SafeForestModel {
        try context.performAndWait {
            let safeQuests: [QuestModel]
            if let questSet = self.quests as? Set<Quest> {
                safeQuests = try questSet.map { try $0.safeObject(context: context) }
            } else {
                safeQuests = []
            }
            
            let safeSculptures: [SculptureModel]
            if let sculptureSet = self.sculptures as? Set<Sculpture> {
                safeSculptures = try sculptureSet.map { try $0.safeObject(context: context) }
            } else {
                safeSculptures = []
            }
            
            let safeTrees: [TreeModel]
            if let treeSet = self.trees as? Set<Tree> {
                safeTrees = try treeSet.map { try $0.safeObject(context: context) }
            } else {
                safeTrees = []
            }
            
            let safeAnimals: [AnimalModel]
            if let animalSet = self.animals as? Set<Animal> {
                safeAnimals = try animalSet.map { try $0.safeObject(context: context) }
            } else {
                safeAnimals = []
            }
            
            return SafeForestModel(
                rainValue: Int(self.rainValue),
                moneyValue: Int(self.moneyValue),
                landHealthPercent: Int(self.landHealthPercent),
                landStatus: self.landStatus,
                isRaining: self.isRaining,
                lastRainUpdateDate: self.lastRainUpdateDate,
                lastDailyResetDate: self.lastDailyResetDate,
                lastWeeklyResetDate: self.lastWeeklyResetDate,
                lastMonthlyResetDate: self.lastMonthlyResetDate,
                quests: safeQuests,
                sculptures: safeSculptures,
                trees: safeTrees,
                animals: safeAnimals
            )
        }
    }
}

// MARK: Generated accessors for quests
extension Forest {

    @objc(addQuestsObject:)
    @NSManaged public func addToQuests(_ value: Quest)

    @objc(removeQuestsObject:)
    @NSManaged public func removeFromQuests(_ value: Quest)

    @objc(addQuests:)
    @NSManaged public func addToQuests(_ values: NSSet)

    @objc(removeQuests:)
    @NSManaged public func removeFromQuests(_ values: NSSet)

}

// MARK: Generated accessors for sculptures
extension Forest {

    @objc(addSculpturesObject:)
    @NSManaged public func addToSculptures(_ value: Sculpture)

    @objc(removeSculpturesObject:)
    @NSManaged public func removeFromSculptures(_ value: Sculpture)

    @objc(addSculptures:)
    @NSManaged public func addToSculptures(_ values: NSSet)

    @objc(removeSculptures:)
    @NSManaged public func removeFromSculptures(_ values: NSSet)

}

// MARK: Generated accessors for trees
extension Forest {

    @objc(addTreesObject:)
    @NSManaged public func addToTrees(_ value: Tree)

    @objc(removeTreesObject:)
    @NSManaged public func removeFromTrees(_ value: Tree)

    @objc(addTrees:)
    @NSManaged public func addToTrees(_ values: NSSet)

    @objc(removeTrees:)
    @NSManaged public func removeFromTrees(_ values: NSSet)

}

// MARK: Generated accessors for animals
extension Forest {

    @objc(addAnimalsObject:)
    @NSManaged public func addToAnimals(_ value: Animal)

    @objc(removeAnimalsObject:)
    @NSManaged public func removeFromAnimals(_ value: Animal)

    @objc(addAnimals:)
    @NSManaged public func addToAnimals(_ values: NSSet)

    @objc(removeAnimals:)
    @NSManaged public func removeFromAnimals(_ values: NSSet)

}

extension Forest : Identifiable {

}
