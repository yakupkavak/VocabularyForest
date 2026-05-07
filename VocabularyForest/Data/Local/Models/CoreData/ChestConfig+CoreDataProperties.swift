//
//  ChestConfig+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

public import Foundation
public import CoreData

public typealias ChestConfigCoreDataPropertiesSet = NSSet

extension ChestConfig {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChestConfig> {
        NSFetchRequest<ChestConfig>(entityName: "ChestConfig")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var configID: String?
    @NSManaged public var season: String?
    @NSManaged public var goldChestDiamondChance: Int16
    @NSManaged public var goldChestWaterChance: Int16
    @NSManaged public var natureChestAnimalChance: Int16
    @NSManaged public var antiqueChestAnimalChance: Int16
    @NSManaged public var goldChestGoldMin: Int16
    @NSManaged public var goldChestGoldMax: Int16
    @NSManaged public var goldChestDiamondMin: Int16
    @NSManaged public var goldChestDiamondMax: Int16
    @NSManaged public var goldChestWaterMin: Int16
    @NSManaged public var goldChestWaterMax: Int16
    @NSManaged public var diamondChestDiamondMin: Int16
    @NSManaged public var diamondChestDiamondMax: Int16
    @NSManaged public var lastUpdatedDate: Date?
}

extension ChestConfig: Identifiable {

}

extension ChestConfig: ConvertSafeModel {
    typealias SafeModel = SafeChestConfigModel

    func safeObject(context: NSManagedObjectContext) throws -> SafeChestConfigModel {
        try context.performAndWait {
            guard let lastUpdatedDate else {
                throw SafeModelError.emptyValue
            }

            return SafeChestConfigModel(
                configID: configID,
                season: season,
                goldChestDiamondChance: Int(goldChestDiamondChance),
                goldChestWaterChance: Int(goldChestWaterChance),
                natureChestAnimalChance: Int(natureChestAnimalChance),
                antiqueChestAnimalChance: Int(antiqueChestAnimalChance),
                goldChestGoldMin: Int(goldChestGoldMin),
                goldChestGoldMax: Int(goldChestGoldMax),
                goldChestDiamondMin: Int(goldChestDiamondMin),
                goldChestDiamondMax: Int(goldChestDiamondMax),
                goldChestWaterMin: Int(goldChestWaterMin),
                goldChestWaterMax: Int(goldChestWaterMax),
                diamondChestDiamondMin: Int(diamondChestDiamondMin),
                diamondChestDiamondMax: Int(diamondChestDiamondMax),
                lastUpdatedDate: lastUpdatedDate
            )
        }
    }
}
