//
//  LocalRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct LocalRewardModel {
    let rewardCount: Int
    let reward: LocalRewardType
}

struct LocalQuestRewardModel {
    let id: String
    let category: QuestRewardModel
    let displayName: RemoteLocalizedText
    let imageSource: ImageSource
    let posterImage: RewardPosterInfo
    let remotePath: String?
    let textColorHex: String?
    let gradientHexes: [String]?
}

enum ImageSource {
    case local
    case remote
    case zip
}

extension ImageSource {
    static func convertImageSource(value: String) -> Self? {
        return switch value {
        case "local":
                .local
        case "remote":
                .remote
        case "zip":
                .zip
        default:
            nil
        }
    }
}

enum LocalRewardType {
    case standart(model: LocalQuestRewardModel)
    case chest(model: LocalChestModel)
}

enum ImageSourceType {
    case appAssets
    case offlineStorage
}

struct RewardPosterInfo {
    let key: String
    let source: ImageSourceType
}

extension LocalRewardType: Rewardable {
    var rewardCount: Int? {
        switch self {
        case .standart(let model):
            model.category.rewardCount
        case .chest(_):
            nil
        }
    }

    var rewardImage: RewardPosterInfo {
        switch self {
        case .standart(let model):
            return model.posterImage
        case .chest(let model):
            return RewardPosterInfo(key: model.closeLocalImagePath, source: .offlineStorage)
        }
    }
    ///Animal, plant vs bilgisi, chest mi gibi bilgiler
    var typeName: String {
        switch self {
        case .standart(let model): return model.category.typeName
        case .chest(let model): return "chest"
        }
    }
    ///Ödülün ismini, altın sayısını vs tutmak için
    var coreDataValueString: String {
        switch self {
        case .standart(let model): return model.category.coreDataValueString
        case .chest(let model): return "chest_core_data_TODO"
        }
    }
    
    var rewardName: String {
        switch self {
        case .standart(let model): return model.displayName.localized
        case .chest(let model): return model.displayName.localized
        }
    }
}

extension LocalRewardType {
    var amountText: String {
        switch self {
        case .standart(let model):
            if let count = model.category.rewardCount {
                return String(localized: "x\(count)")
            }
            return "1"
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
