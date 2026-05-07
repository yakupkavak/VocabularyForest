//
//  ChestRewardItem+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

public import Foundation
public import CoreData

public typealias ChestRewardItemCoreDataPropertiesSet = NSSet

extension ChestRewardItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChestRewardItem> {
        NSFetchRequest<ChestRewardItem>(entityName: "ChestRewardItem")
    }

    @NSManaged public var id: String?
    @NSManaged public var chestType: String?
    @NSManaged public var rewardCategory: String?
    @NSManaged public var modelKey: String?
    @NSManaged public var probabilityWeight: Double
    @NSManaged public var mediaSourceType: String?
    @NSManaged public var mediaFileType: String?
    @NSManaged public var previewImageURL: String?
    @NSManaged public var sourceFieldKey: String?
    @NSManaged public var sourceVersion: String?
    @NSManaged public var lastUpdatedDate: Date?
}

extension ChestRewardItem: Identifiable {

}

extension ChestRewardItem: ConvertSafeModel {
    typealias SafeModel = SafeChestRewardItemModel

    func safeObject(context: NSManagedObjectContext) throws -> SafeChestRewardItemModel {
        try context.performAndWait {
            guard let id = id?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !id.isEmpty,
                  let chestType = chestType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !chestType.isEmpty,
                  let rewardCategory = rewardCategory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !rewardCategory.isEmpty,
                  let modelKey = modelKey?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !modelKey.isEmpty,
                  let mediaSourceType = mediaSourceType?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !mediaSourceType.isEmpty,
                  let mediaFileType = mediaFileType?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !mediaFileType.isEmpty,
                  let lastUpdatedDate else {
                throw SafeModelError.emptyValue
            }

            return SafeChestRewardItemModel(
                id: id,
                chestType: chestType,
                rewardCategory: rewardCategory,
                modelKey: modelKey,
                probabilityWeight: probabilityWeight > 0 ? probabilityWeight : 1.0,
                mediaSourceType: mediaSourceType,
                mediaFileType: mediaFileType,
                previewImageURL: previewImageURL,
                sourceFieldKey: sourceFieldKey,
                sourceVersion: sourceVersion,
                lastUpdatedDate: lastUpdatedDate
            )
        }
    }
}
