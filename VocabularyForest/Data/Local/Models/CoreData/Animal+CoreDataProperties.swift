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

    @NSManaged public var createdDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var isAlive: Bool
    @NSManaged public var healtValue: Int16
    @NSManaged public var xPosition: Double
    @NSManaged public var yPosition: Double
    @NSManaged public var forest: Forest?

}

extension Animal : Identifiable {

}
