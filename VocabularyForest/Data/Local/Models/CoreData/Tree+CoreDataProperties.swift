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
    @NSManaged public var createdDate: Date?
    @NSManaged public var healthValue: Int16
    @NSManaged public var isAlive: Bool
    @NSManaged public var xPosition: Double
    @NSManaged public var yPosition: Double
    @NSManaged public var forest: Forest?
    @NSManaged public var characterName: String?

}

extension Tree: ConvertSafeModel {
    typealias SafeModel = TreeModel
    
    func safeObject() throws -> TreeModel {
        if let id, let assetName, let createdDate, let characterName {
            return TreeModel(
                id: id,
                assetName: assetName,
                characterName: characterName, isAlive: self.isAlive,
                createdDate: createdDate,
                treeHealthValue: Int(self.healthValue),
                xPosition: self.xPosition,
                yPosition: self.yPosition
            )
        }
        throw SafeModelError.emptyValue
    }
}

extension Tree : Identifiable {

}
