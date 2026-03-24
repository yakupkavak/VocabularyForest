//
//  DailyBounty.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.03.2026.
//

import Foundation

enum BountyStatus {
    case claimed
    case passed
    case ready
    case locked
}

// MARK: - DAILY BOUNTY MODEL

enum DailyBountyModel {
    case standart(model: QuestRewardModel)
    case chest(model: ChestBountyModel)
}

extension DailyBountyModel: Rewardable {
    var rewardCount: Int? {
        switch self {
        case .standart(let model):
            model.rewardCount
        case .chest(let model):
            nil
        }
    }

    var rewardImage: String {
        switch self {
        case .standart(let model):
            return model.rewardImage
        case .chest(let model):
            return model.rewardImage
        }
    }
    
    var typeName: String {
        switch self {
        case .standart(let model): return model.typeName
        case .chest(let model): return model.typeName
        }
    }
    
    var coreDataValueString: String {
        switch self {
        case .standart(let model): return model.coreDataValueString
        case .chest(let model): return model.coreDataValueString
        }
    }
    
    var rewardName: String {
        switch self {
        case .standart(let model): return model.rewardName
        case .chest(let model): return model.rewardName
        }
    }
}

// MARK: - CHEST BOUNTY MODEL

enum ChestBountyModel {
    case gold
    case nature
    case diamond
    case antique
}

enum ChestStatus {
    case open
    case close
}

extension ChestBountyModel: Rewardable {
    var rewardCount: Int? {
        return nil
    }
    
    var coreDataValueString: String {
        return switch  self {
            case .gold:
               "gold_chest"
            case .nature:
                "nature_chest"
            case .diamond:
                "diamond_chest"
            case .antique:
                "antique_chest"
            }
    }
    
    var rewardImage: String {
        return switch self {
        case .gold:
            "gold_chest_close"
        case .nature:
            "nature_chest_close"
        case .diamond:
            "diamond_chest_close"
        case .antique:
            "antique_chest_close"
        }
    }
    
    var typeName: String {
        return switch  self {
        case .gold:
           "gold_chest"
        case .nature:
            "nature_chest"
        case .diamond:
            "diamond_chest"
        case .antique:
            "antique_chest"
        }
    }
    
    var rewardName: String {
        return switch  self {
        case .gold:
           String(localized: "gold_chest")
        case .nature:
            String(localized:  "nature_chest")
        case .diamond:
            String(localized:  "diamond_chest")
        case .antique:
            String(localized:  "antique_chest")
        }
    }
    
    func getChestImage(status: ChestStatus) -> String {
        return switch self {
        case .gold:
            status == .open ? "gold_chest_open" : "gold_chest_close"
        case .nature:
            status == .open ? "nature_chest_open" : "nature_chest_close"
        case .diamond:
            status == .open ? "diamond_chest_open" : "diamond_chest_close"
        case .antique:
            status == .open ? "antique_chest_open" : "antique_chest_close"
        }
    }
}
