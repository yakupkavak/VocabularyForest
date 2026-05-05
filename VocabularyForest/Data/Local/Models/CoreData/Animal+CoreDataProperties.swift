//
//  Animal+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//
//

public import Foundation
public import CoreData


public typealias AnimalCoreDataPropertiesSet = NSSet

extension Animal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Animal> {
        return NSFetchRequest<Animal>(entityName: "Animal")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var createdDate: Date?
    @NSManaged public var assetName: String?
    @NSManaged public var isAlive: Bool
    @NSManaged public var healtValue: Int16
    @NSManaged public var xPosition: Double
    @NSManaged public var yPosition: Double
    @NSManaged public var forest: Forest?
    @NSManaged public var characterName: String?
    @NSManaged public var lastUpdatedDate: Date?

}

extension Animal: ConvertSafeModel {
    typealias SafeModel = AnimalModel
    
    func safeObject(context: NSManagedObjectContext) throws -> AnimalModel {
        try context.performAndWait {
            if let id, let createdDate, let assetName, let characterName, let lastUpdatedDate {
                return AnimalModel(
                    id: id,
                    characterName: characterName,
                    assetName: assetName,
                    createdDate: createdDate,
                    healthValue: Int(healtValue),
                    isAlive: isAlive,
                    xPosition: xPosition,
                    yPosition: yPosition,
                    lastUpdatedDate: lastUpdatedDate
                )
            }
            throw SafeModelError.emptyValue
        }
    }
}

extension Animal : Identifiable {

}
