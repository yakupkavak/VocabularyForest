//
//  MockQuestModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.06.2026.
//

@testable import VocabularyForest
import Foundation

extension QuestModel {
    static func mock(id: String = "quest_id", type: QuestType = .daily, reward: LocalRewardModel = LocalRewardModel.mock(), targetCount: Int = 5) -> QuestModel {
        return QuestModel(
            id: id,
            type: type,
            title: "Title",
            description: "Descriiption",
            reward: reward,
            lastUpdatedDate: Date(),
            status: .active,
            targetCount: targetCount,
            currentProgressCount: 1,
            questionType: .competitive,
            battleEnemyModel: .classic,
            gameLevel: .easy
        )
    }
}
