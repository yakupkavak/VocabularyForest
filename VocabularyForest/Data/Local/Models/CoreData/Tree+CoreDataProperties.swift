//
//  Tree+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//
//

public import Foundation
public import CoreData

public typealias TreeCoreDataPropertiesSet = NSSet

extension Tree {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tree> {
        return NSFetchRequest<Tree>(entityName: "Tree")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var assetName: String?
    @NSManaged public var assetSourceString: String?
    @NSManaged public var posterKey: String?
    @NSManaged public var posterSourceString: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var healthValue: Int16
    @NSManaged public var isAlive: Bool
    @NSManaged public var xPosition: Double
    @NSManaged public var yPosition: Double
    @NSManaged public var forest: Forest?
    @NSManaged public var characterName: String?
    @NSManaged public var lastUpdatedDate: Date?
    @NSManaged public var rewardId: String?
    
}

extension Tree: ConvertSafeModel {
    typealias SafeModel = TreeModel
    
    func safeObject(context: NSManagedObjectContext) throws -> TreeModel {
        try context.performAndWait {
            if let id, let assetName, let createdDate, let characterName, let lastUpdatedDate, let posterKey, let assetSourceString, let posterSourceString {
                
                let mainAssetSource = ImageSourceType(rawValue: assetSourceString) ?? .offlineStorage
                let posterSource = ImageSourceType(rawValue: posterSourceString) ?? .offlineStorage
                let posterReference = RewardAssetReference(key: posterKey, source: posterSource)
                
                return TreeModel(
                    id: id,
                    assetName: assetName,
                    createdDate: createdDate,
                    characterName: characterName,
                    assetSource: mainAssetSource,
                    poster: posterReference,
                    isAlive: isAlive,
                    treeHealthValue: Int(healthValue),
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

extension Tree : Identifiable {

}
