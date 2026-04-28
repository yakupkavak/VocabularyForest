//
//  ChestBountyModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

enum ChestBountyModel: Encodable {
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
