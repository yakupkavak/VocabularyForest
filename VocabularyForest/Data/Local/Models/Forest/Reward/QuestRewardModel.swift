//
//  QuestRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.03.2026.
//

protocol Rewardable {
    var typeName: String { get }
    var coreDataValueString: String { get }
    var rewardName: String { get }
    var rewardImage: RewardImageInfo { get }
    var rewardCount: Int? { get }
}

enum QuestRewardModel: Hashable, Encodable {
    case animal(modelName: String)
    case plant(modelName: String)
    case gold(count: Int)
    case water(count: Int)
    case diamond(count: Int)
    case sculpture(modelName: String)
}

extension QuestRewardModel: Rewardable {
    var rewardCount: Int? {
        return switch self {
        case .gold(let size):
            size
        case .water(let count):
            count
        case .diamond(let count):
            count
        default:
            nil
        }
    }
    
    var rewardImage: String {
        return switch self {
        case .animal(let modelName):
            modelName
        case .plant(let modelName):
            modelName
        case .gold(let count):
            "gold_icon"
        case .water(let count):
            "water_icon"
        case .sculpture(let modelName):
            modelName
        case .diamond(count: let count):
            "diamond_icon"
        }
    }
    
    var typeName: String {
        switch self {
        case .animal: return "animal"
        case .plant: return "plant"
        case .water: return "water"
        case .sculpture: return "sculpture"
        case .gold: return "gold"
        case .diamond: return "diamond"
        }
    }

    var coreDataValueString: String {
        switch self {
        case .animal(let name):
            name
        case .plant(let name):
            name
        case .water(let count):
            String(count)
        case .sculpture(let name):
            name
        case .gold(let count):
            String(count)
        case .diamond(let count):
            String(count)
        }
    }
    
    var rewardName: String {
        switch self {
        case .animal(let name):
            return AnimalReward(rawValue: name)?.localizedKey ?? name
        case .plant(let name):
            return PlantReward(rawValue: name)?.localizedKey ?? name
        case .water(let count):
            return String(count)
        case .sculpture(let name):
            return SculptureReward(rawValue: name)?.localizedKey ?? name
        case .gold(let count):
            return String(count)
        case .diamond(let count):
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
            case "diamond":
                .diamond(count: Int(value) ?? 1)
            default:
                .water(count: 1)
        }
    }
}
