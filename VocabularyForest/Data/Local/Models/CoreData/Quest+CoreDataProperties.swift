//
//  Quest+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//
//

public import Foundation
public import CoreData


public typealias QuestCoreDataPropertiesSet = NSSet

extension Quest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Quest> {
        return NSFetchRequest<Quest>(entityName: "Quest")
    }

    @NSManaged public var id: String?
    @NSManaged public var status: String?
    @NSManaged public var currentProgressCount: Int16
    @NSManaged public var forest: Forest?
    @NSManaged public var lastUpdatedDate: Date?

}

// MARK: - EXTENSION SAFE MODEL

extension Quest: ConvertSafeModel {
    typealias SafeModel = QuestTrackModel
    func safeObject(context: NSManagedObjectContext) throws -> QuestTrackModel {
        try context.performAndWait {
            if let questId = self.id, let status, let lastUpdatedDate {
                return QuestTrackModel(
                    id: questId,
                    lastUpdateDate: lastUpdatedDate,
                    status: QuestStatus.convertFromCoreData(string: status),
                    currentProgressCount: Int(currentProgressCount)
                )
            }
            throw SafeModelError.emptyValue
        }
    }
}

extension Quest : Identifiable {

}
