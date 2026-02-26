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

}

// MARK: - EXTENSION SAFE MODEL

extension Quest: ConvertSafeModel {
    typealias SafeModel = QuestModel

    func safeObject() throws -> QuestModel {
        if let questId = self.id, let questTitle = self.title, let questDescription = self.description_quest {
            return QuestModel(
                id: questId,
                type: QuestType.convertFromCoreData(string: self.questType),
                title: questTitle,
                description: questDescription,
                reward: QuestRewardModel.convertFromCoreData(type: self.rewardType, value: self.rewardValue),
                status: QuestStatus.convertFromCoreData(string: self.status),
                targetCount: Int(self.targetCount),
                currentProgressCount: Int(self.currentProgressCount),
                questionType: BattleQuestionType.convertFromCoreData(type: self.questType),
                battleEnemyModel: BattleEnemyModel.convertFromCoreData(string: self.battleEnemyModel),
                gameLevel: GameLevel.convertFromCoreData(value: self.gameLevel)
            )
        }
        throw SafeModelError.emptyValue
    }
}

extension Quest : Identifiable {

}
