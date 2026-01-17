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
    @NSManaged public var name: String?
    @NSManaged public var xPosition: Double
    @NSManaged public var yPosition: Double
    @NSManaged public var forest: Forest?
    @NSManaged public var characterName: String?

}

extension Sculpture : Identifiable {

}
