//
//  TaskModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.11.2025.
//

import Foundation
import SwiftUI

// MARK: - ENUMS

enum QuestStatus: String {
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

enum QuestRewardModel {
    case animal(name: String)
    case plant(name: String)
    case gold(count: Int)
    case water(count: Int)
    case sculpture(name: String)
}

extension QuestRewardModel {
    var typeName: String {
        switch self {
        case .animal: return "animal"
        case .plant: return "plant"
        case .water: return "water"
        case .sculpture: return "sculpture"
        case .gold: return "gold"
        }
    }

    var valueString: String {
        switch self {
        case .animal(let name):
            name
        case .plant(let name):
            name
        case .water(let count):
            String(count)
        case .sculpture(let name):
            name
        case .gold(count: let count):
            String(count)
        }
    }

    static func convertFromCoreData(type: String?, value: String?) -> QuestRewardModel {
        guard let type, let value else {
            return .water(count: 1)
        }
        return switch type {
            case "animal":
                .animal(name: value)
            case "plant":
                .plant(name: value)
            case "water":
                .water(count: Int(value) ?? 1)
            case "sculpture":
                .sculpture(name: value)
            default:
                .water(count: 1)
        }
    }
}

// TODO: - FUTURE I WILL CREATE FIREBASE WITH MONTLY FOREST COMPONENTS

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
        guard let string else { return QuestType.daily }
        
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
    var questionType: BattleQuestionType
    var battleMode: BattleModeModel
    var gameLevel: GameLevel

    // MARK: - COMPUTED PROPERTIES

    var currentRatio: Int {
        Int(Double(currentProgressCount) / Double(targetCount))
    }
    var isFinished: Bool {
        return currentProgressCount >= targetCount
    }
}
