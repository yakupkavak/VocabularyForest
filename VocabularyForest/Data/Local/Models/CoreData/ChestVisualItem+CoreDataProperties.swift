//
//  ChestVisualItem+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

public import Foundation
public import CoreData

public typealias ChestVisualItemCoreDataPropertiesSet = NSSet

extension ChestVisualItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChestVisualItem> {
        NSFetchRequest<ChestVisualItem>(entityName: "ChestVisualItem")
    }

    @NSManaged public var id: String?
    @NSManaged public var chestType: String?
    @NSManaged public var closedImagePath: String?
    @NSManaged public var openImagePath: String?
    @NSManaged public var lastUpdatedDate: Date?
}

extension ChestVisualItem: Identifiable {

}

extension ChestVisualItem: ConvertSafeModel {
    typealias SafeModel = SafeChestVisualItemModel

    func safeObject(context: NSManagedObjectContext) throws -> SafeChestVisualItemModel {
        try context.performAndWait {
            guard let id = id?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !id.isEmpty,
                  let chestType = chestType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !chestType.isEmpty,
                  let closedImagePath = closedImagePath?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !closedImagePath.isEmpty,
                  let openImagePath = openImagePath?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !openImagePath.isEmpty,
                  let lastUpdatedDate else {
                throw SafeModelError.emptyValue
            }

            return SafeChestVisualItemModel(
                id: id,
                chestType: chestType,
                closedImagePath: closedImagePath,
                openImagePath: openImagePath,
                lastUpdatedDate: lastUpdatedDate
            )
        }
    }
}
