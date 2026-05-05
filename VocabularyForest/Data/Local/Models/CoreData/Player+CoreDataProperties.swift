//
//  Player+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 13.04.2026.
//
//

public import Foundation
public import CoreData


public typealias PlayerCoreDataPropertiesSet = NSSet

extension Player {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Player> {
        return NSFetchRequest<Player>(entityName: "Player")
    }

    @NSManaged public var name: String?
    @NSManaged public var lastUpdatedDate: Date?

}

extension Player: ConvertSafeModel {
    typealias SafeModel = PlayerModel

    func safeObject(context: NSManagedObjectContext) throws -> PlayerModel {
        try context.performAndWait {
            if let name, let lastUpdatedDate{
                return PlayerModel(name: name, lastUpdateDate: lastUpdatedDate)
            }else {
                throw SafeModelError.emptyValue
            }
        }
    }
}
