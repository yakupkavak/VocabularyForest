//
//  LocalRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

enum LocalRewardModel {
    case standart(model: QuestRewardModel)
    case chest(model: LocalChestModel)
}

enum ImageSourceType {
    case appAssets
    case offlineStorage
}

struct RewardImageInfo {
    let key: String
    let source: ImageSourceType
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

    var rewardImage: RewardImageInfo {
        switch self {
        case .standart(let model):
            return RewardImageInfo(key: model.rewardImage, source: .appAssets)
        case .chest(let model):
            return RewardImageInfo(key: model.closeLocalImagePath, source: .offlineStorage)
        }
    }
    ///Animal, plant vs bilgisi, chest mi gibi bilgiler
    var typeName: String {
        switch self {
        case .standart(let model): return model.typeName
        case .chest(let model): return "chest"
        }
    }
    ///Ödülün ismini, altın sayısını vs tutmak için
    var coreDataValueString: String {
        switch self {
        case .standart(let model): return model.coreDataValueString
        case .chest(let model): return "chest_core_data_TODO"
        }
    }
    
    var rewardName: String {
        switch self {
        case .standart(let model): return model.rewardName
        case .chest(let model): return model.displayName.localized
        }
    }
}

extension LocalRewardModel {
    var amountText: String {
        switch self {
        case .standart(let model):
            if let count = model.rewardCount {
                return String(localized: "x\(count)")
            }
            return model.rewardName
        case .chest(let model):
            return "1"
        }
    }

    var isChestReward: Bool {
        if case .chest = self {
            return true
        }
        return false
    }
}
