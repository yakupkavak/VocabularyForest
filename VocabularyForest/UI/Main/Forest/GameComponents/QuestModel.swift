//
//  TaskModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.11.2025.
//

import Foundation

// MARK: - ENUMS

enum QuestStatus: String {
    case locked
    case active
    case completed
    case claimed
}

enum QuestRewardModel {
    case animal(name: String)
    case plant(name: String)
    case water(count: Int)
    case sculpture(name: String)
}

enum QuestType {
    case daily
    case weekly
    case monthly
    case special
    
    private var titleKey: String.LocalizationValue {
        switch self {
        case .daily:
            "quest_daily_type_title"
        case .weekly:
            "quest_weekly_type_title"
        case .monthly:
            "quest_monthly_type_title"
        case .special:
            "quest_eternal_type_title"
        }
    }
    var localizedTitle: String {
        String(localized: titleKey)
    }
}

// MARK: MODEL

struct QuestModel: Identifiable {
    
    // MARK: - PROPERTIES
    
    let id: UUID
    let type: QuestType
    let title: String
    let description: String
    let reward: QuestRewardModel
    var status: QuestStatus
    var targetCount: Int
    var currentProgressCount: Int
    
    // MARK: - COMPUTED PROPERTIES

    var currentRatio: Int {
        Int(Double(currentProgressCount) / Double(targetCount))
    }
    var isFinished: Bool {
        return currentProgressCount >= targetCount
    }
}
