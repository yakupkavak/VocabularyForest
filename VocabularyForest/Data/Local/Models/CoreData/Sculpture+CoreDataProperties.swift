//
//  Sculpture+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//
//

public import Foundation
public import CoreData

public typealias SculptureCoreDataPropertiesSet = NSSet

extension Sculpture {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Sculpture> {
        return NSFetchRequest<Sculpture>(entityName: "Sculpture")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var createdDate: Date?
    @NSManaged public var assetName: String?
    @NSManaged public var assetSourceString: String?
    @NSManaged public var posterKey: String?
    @NSManaged public var posterSourceString: String?
    @NSManaged public var xPosition: Double
    @NSManaged public var yPosition: Double
    @NSManaged public var forest: Forest?
    @NSManaged public var characterName: String?
    @NSManaged public var lastUpdatedDate: Date?
    @NSManaged public var rewardId: String?
    
}

extension Sculpture: ConvertSafeModel {
    typealias SafeModel = SculptureModel
    
    func safeObject(context: NSManagedObjectContext) throws -> SculptureModel {
        try context.performAndWait {
            if let id, let createdDate, let assetName, let characterName, let lastUpdatedDate, let posterKey, let assetSourceString, let posterSourceString {
                
                let mainAssetSource = ImageSourceType(rawValue: assetSourceString) ?? .offlineStorage
                let posterSource = ImageSourceType(rawValue: posterSourceString) ?? .offlineStorage
                let posterReference = RewardAssetReference(key: posterKey, source: posterSource)
                
                return SculptureModel(
                    id: id,
                    assetName: assetName,
                    createdDate: createdDate,
                    characterName: characterName,
                    assetSource: mainAssetSource,
                    poster: posterReference,
                    xPosition: xPosition,
                    yPosition: yPosition,
                    lastUpdatedDate: lastUpdatedDate,
                    rewardId: rewardId
                )
            }
            throw SafeModelError.emptyValue
        }
    }
}

extension Sculpture : Identifiable {

}
