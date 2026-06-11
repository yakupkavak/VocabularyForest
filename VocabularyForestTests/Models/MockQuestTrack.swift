//
//  MockQuestTrack.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.06.2026.
//

@testable import VocabularyForest
import Foundation

extension QuestTrackModel {
    static func mock(
        id: String = "1",
        lastUpdatedDate: Date = Date(),
        status: QuestStatus = .active,
        currentProgressCount: Int = 0
    ) -> QuestTrackModel {
        QuestTrackModel(
            id: id,
            lastUpdatedDate: lastUpdatedDate,
            status: status,
            currentProgressCount: currentProgressCount
        )
    }
}
