//
//  TaskModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.11.2025.
//

import Foundation
import SwiftUI

// MARK: - ENUMS

enum QuestStatus: String, Hashable {
    case locked
    case active
    case completed
    case claimed
}

extension QuestStatus {
    var valueForCoreData: String {
        switch self {
        case .locked:
            "locked"
        case .active:
            "active"
        case .completed:
            "completed"
        case .claimed:
            "claimed"
        }
    }
    static func convertFromCoreData(string: String?) -> QuestStatus {
        guard let string else {
            return .locked
        }
        return switch string {
            case "locked":
                .locked
            case "active":
                .active
            case "completed":
                .completed
            case "claimed":
                .claimed
            default:
                .locked
        }
    }
}

// TODO: - FUTURE I WILL CREATE FIREBASE WITH MONTLY FOREST COMPONENTS

enum QuestType: Hashable {
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
    var imageIconName: String {
        switch self {
        case .daily:
            "daily_quest_icon"
        case .weekly:
            "weekly_quest_icon"
        case .monthly:
            "monthly_quest_icon"
        case .special:
            "special_quest_icon"
        }
    }
    var backgroundColor: Color {
        switch self {
        case .daily:
            Color.brown500
        case .weekly:
            Color.brown500
        case .monthly:
            Color.brown500
        case .special:
            Color.brown500
        }
    }
}

extension QuestType {
    var valueForCoreData: String {
        switch self {
        case .daily:
            "daily"
        case .weekly:
            "weekly"
        case .monthly:
            "monthly"
        case .special:
            "special"
        }
    }
    
    static func convertFromCoreData(string: String?) -> QuestType {
        return switch string {
            case "daily":
                .daily
            case "weekly":
                .weekly
            case "monthly":
                .monthly
            case "special":
                .special
            default:
                .daily
        }
    }
}

// MARK: MODEL

struct QuestModel: Identifiable, Hashable {
    
    // MARK: - PROPERTIES
    
    let id: String
    let type: QuestType
    let title: String
    let description: String
    let reward: LocalRewardModel
    var lastUpdatedDate: Date
    var status: QuestStatus
    var targetCount: Int
    var currentProgressCount: Int
    var questionType: BattleQuestionType
    let battleEnemyModel: BattleEnemyModel
    let gameLevel: GameLevel

    // MARK: - COMPUTED PROPERTIES

    var currentRatio: Double {
        guard targetCount > 0 else { return 0 }
        return Double(currentProgressCount) / Double(targetCount)
    }
    var isFinished: Bool {
        return currentProgressCount >= targetCount
    }
}
