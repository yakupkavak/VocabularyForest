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
    @NSManaged public var xPosition: Double
    @NSManaged public var yPosition: Double
    @NSManaged public var forest: Forest?
    @NSManaged public var characterName: String?
    @NSManaged public var lastUpdatedDate: Date?
    
}

extension Sculpture: ConvertSafeModel {
    typealias SafeModel = SculptureModel
    
    func safeObject(context: NSManagedObjectContext) throws -> SculptureModel {
        try context.performAndWait {
            if let id, let createdDate, let assetName, let characterName, let lastUpdatedDate {
                return SculptureModel(
                    id: id,
                    assetName: assetName,
                    characterName: characterName,
                    createdDate: createdDate,
                    xPosition: self.xPosition,
                    yPosition: self.yPosition,
                    lastUpdatedDate: lastUpdatedDate
                )
            }
            throw SafeModelError.emptyValue
        }
    }
}

extension Sculpture : Identifiable {

}
