//
//  LocalRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

enum LocalRewardModel: Encodable {
    case standart(model: QuestRewardModel)
    case chest(model: ChestBountyModel)
}

extension LocalRewardModel: Rewardable {
    var rewardCount: Int? {
        switch self {
        case .standart(let model):
            model.rewardCount
        case .chest(_):
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

extension LocalRewardModel {
    var iconName: String {
        rewardImage
    }

    var amountText: String {
        switch self {
        case .standart(let model):
            if let count = model.rewardCount {
                return String(localized: "x\(count)")
            }
            return model.rewardName
        case .chest(let model):
            return model.rewardName
        }
    }

    var isChestReward: Bool {
        if case .chest = self {
            return true
        }
        return false
    }
}
