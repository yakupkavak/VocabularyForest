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
    @NSManaged public var assetSourceString: String?
    @NSManaged public var posterKey: String?
    @NSManaged public var posterSourceString: String?
    @NSManaged public var isAlive: Bool
    @NSManaged public var healthValue: Int16
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
            if let id, let createdDate, let assetName, let characterName, let lastUpdatedDate, let posterKey, let assetSourceString, let posterSourceString {
                let mainAssetSource = ImageSourceType(rawValue: assetSourceString) ?? .offlineStorage
                let posterSource = ImageSourceType(rawValue: posterSourceString) ?? .offlineStorage
                let posterReference = RewardAssetReference(key: posterKey, source: posterSource)
                return AnimalModel(
                    id: id,
                    assetName: assetName,
                    createdDate: createdDate,
                    characterName: characterName,
                    assetSource: mainAssetSource,
                    poster: posterReference,
                    healthValue: Int(healthValue),
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
