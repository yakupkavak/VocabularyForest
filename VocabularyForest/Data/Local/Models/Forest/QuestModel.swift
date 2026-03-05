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

enum QuestRewardModel: Hashable {
    case animal(modelName: String)
    case plant(modelName: String)
    case gold(count: Int)
    case water(count: Int)
    case sculpture(modelName: String)
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
    
    var rewardName: String {
        switch self {
        case .animal(let name):
            return if name == "WhiteCat" {
                "white_cat_name"
            }else if name == "Cat" {
                "cat_name"
            }else if name == "Dog" {
                "dog_name"
            }else {
                name
            }
        case .plant(let name):
            return if name == "DesertStarBloom" {
                "desert_star_bloom_name"
            }else if name == "CrystalReed" {
                "crystal_reed_name"
            }else if name == "BlueFlameBush" {
                "blue_flame_bush_name"
            }else if name == "Emberbud" {
                "emberbud_name"
            }else if name == "MoonBell" {
                "moon_beel_name"
            }else if name == "SunFlower" {
                "sun_flower_name"
            }
            else {
                name
            }
        case .water(let count):
            return String(count)
        case .sculpture(let name):
            return if name == "EmeraldDragon" {
                "emerald_dragon_name"
            }else if name == "Deer" {
                "ancient_deer_name"
            }else if name == "AncientLancer" {
                "ancient_lancer"
            }else {
                name
            }
        case .gold(count: let count):
            return String(count)
        }
    }

    static func convertFromCoreData(type: String?, value: String?) -> QuestRewardModel {
        guard let type, let value else {
            return .water(count: 1)
        }
        return switch type {
            case "animal":
                .animal(modelName: value)
            case "plant":
                .plant(modelName: value)
            case "water":
                .water(count: Int(value) ?? 1)
            case "sculpture":
                .sculpture(modelName: value)
            case "gold":
                .gold(count: Int(value) ?? 1)
            default:
                .water(count: 1)
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
    
    let id: UUID
    let type: QuestType
    let title: String
    let description: String
    let reward: QuestRewardModel
    var status: QuestStatus
    var targetCount: Int
    var currentProgressCount: Int
    var questionType: BattleQuestionType
    var battleEnemyModel: BattleEnemyModel
    var gameLevel: GameLevel

    // MARK: - COMPUTED PROPERTIES

    var currentRatio: Int {
        Int(Double(currentProgressCount) / Double(targetCount))
    }
    var isFinished: Bool {
        return currentProgressCount >= targetCount
    }
}

extension QuestModel {
    static func convertModel(quest: Quest, id: UUID) -> QuestModel {
        let model = QuestModel(
            id: id,
            type: QuestType.convertFromCoreData(string: quest.type),
            title: quest.title ?? "Quest",
            description: quest.description_quest ?? "Unexpected error",
            reward: .convertFromCoreData(type: quest.rewardType, value: quest.rewardValue),
            status: .convertFromCoreData(string: quest.status),
            targetCount: Int(quest.targetCount),
            currentProgressCount: Int(quest.currentProgressCount),
            questionType: .convertFromCoreData(type: quest.questType),
            battleEnemyModel: .convertFromCoreData(string: quest.battleEnemyModel),
            gameLevel: .convertFromCoreData(value: quest.gameLevel),
        )
        return model
    }
}
