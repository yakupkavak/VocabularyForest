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

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var title: String?
    @NSManaged public var description_quest: String?
    @NSManaged public var rewardType: String?
    @NSManaged public var rewardValue: String?
    @NSManaged public var status: String?
    @NSManaged public var targetCount: Int16
    @NSManaged public var currentProgressCount: Int16
    @NSManaged public var forest: Forest?
    @NSManaged public var questType: String?
    @NSManaged public var battleEnemyModel: String?
    @NSManaged public var gameLevel: String?
    @NSManaged public var lastUpdatedDate: Date?

}

// MARK: - EXTENSION SAFE MODEL

extension Quest: ConvertSafeModel {
    typealias SafeModel = QuestModel

    func safeObject(context: NSManagedObjectContext) throws -> QuestModel {
        try context.performAndWait {
            if let questId = self.id, let questType, let questTitle = self.title, let questDescription = self.description_quest, let rewardType, let status, let gameLevel, let battleEnemyModel, let type, let lastUpdatedDate {
                return QuestModel(
                    id: questId,
                    type: QuestType.convertFromCoreData(string: type),
                    title: questTitle,
                    description: questDescription,
                    reward: QuestRewardModel.convertFromCoreData(type: rewardType, value: rewardValue),
                    lastUpdatedDate: lastUpdatedDate,
                    status: QuestStatus.convertFromCoreData(string: status),
                    targetCount: Int(targetCount),
                    currentProgressCount: Int(currentProgressCount),
                    questionType: BattleQuestionType.convertFromCoreData(type: questType),
                    battleEnemyModel: BattleEnemyModel.convertFromCoreData(string: battleEnemyModel),
                    gameLevel: GameLevel.convertFromCoreData(value: gameLevel)
                )
            }
            throw SafeModelError.emptyValue
        }
    }
}

extension Quest : Identifiable {

}
