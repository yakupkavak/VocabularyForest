//
//  LocalRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct LocalRewardModel: Hashable {
    let rewardCount: Int
    let reward: LocalRewardType
}

struct LocalQuestRewardModel: Hashable {
    let id: String
    let category: QuestRewardModel
    let displayName: RemoteLocalizedText
    let assetName: String
    let imageSource: ImageSource
    let posterImage: RewardAssetReference
    let remotePath: String?
    let remoteAssetVersion: Int?
    let textColorHex: String?
    let textStrokeColorHex: String?
    let gradientHexes: [String]?
}

enum ImageSource: Hashable {
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

enum LocalRewardType: Hashable {
    case standart(model: LocalQuestRewardModel)
    case chest(model: LocalChestModel)
}

enum ImageSourceType: String, Hashable {
    case appAssets
    case offlineStorage
}

struct RewardAssetReference: Hashable {
    let key: String
    let source: ImageSourceType
}

extension LocalRewardType {
    var posterImage: RewardAssetReference {
        switch self {
        case .standart(let model):
            model.posterImage
        case .chest(let model):
            model.closeLocalImagePath
        }
    }
    var displayName: RemoteLocalizedText {
        switch self {
        case .standart(let model):
            model.displayName
        case .chest(let model):
            model.displayName
        }
    }
}

/*
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
*/
