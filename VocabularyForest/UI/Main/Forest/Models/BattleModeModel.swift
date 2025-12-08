//
//  BattleModeModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 1.12.2025.
//

enum BattleModeModel: Hashable, Codable {
    case iceElemental
    case fireElemental
    case natureElemental
    case sandDragon
    case fireDragon
    case classic
    
    var assetModels: [EnemyCharacterModel] {
        switch self {
        case .iceElemental:
            [EnemyCharacterModel(assetName: "IceElemental", characterName: "Ice Elemental", isBoss: true)]
        case .fireElemental:
            [EnemyCharacterModel(assetName: "FireElemental", characterName: "Fire Elemental", isBoss: true)]
        case .natureElemental:
            [EnemyCharacterModel(assetName: "NatureElemental", characterName: "Nature Elemental", isBoss: true)]
        case .sandDragon:
            [EnemyCharacterModel(assetName: "SandDragon", characterName: "Sand Dragon", isBoss: true)]
        case .fireDragon:
            [EnemyCharacterModel(assetName: "FireDragon", characterName: "Fire Dragon", isBoss: true)]
        case .classic:
            [
                EnemyCharacterModel(assetName: "Skeleton", characterName: "Skeleton", isBoss: false),
                EnemyCharacterModel(assetName: "Ghost", characterName: "Ghost", isBoss: false),
                EnemyCharacterModel(assetName: "DarkKnight", characterName: "Dark Knight", isBoss: false),
                EnemyCharacterModel(assetName: "BigKnight", characterName: "Big Knight", isBoss: false),
                EnemyCharacterModel(assetName: "SkeletonDragon", characterName: "Skeleton Dragon", isBoss: false),
                EnemyCharacterModel(assetName: "Vampire", characterName: "Vampire", isBoss: true)
            ]
        }
    }
}

extension BattleModeModel {
    var title: String {
        switch self {
        case .iceElemental:
            "Ice Elemental"
        case .fireElemental:
            "Fire Elemental"
        case .natureElemental:
            "Nature Elemental"
        case .sandDragon:
            "Sand Dragon"
        case .fireDragon:
            "Fire Dragon"
        case .classic:
            "Classic"
        }
    }
    var background: String {
        switch self {
        case .iceElemental:
            "battle_background_2"
        case .fireElemental:
            "battle_background_3"
        case .natureElemental:
            "battle_background_3"
        case .sandDragon:
            "battle_background_1"
        case .fireDragon:
            "battle_background_7"
        case .classic:
            "battle_background_0"
        }
    }
    var valueForCoreData: String {
        switch self {
        case .iceElemental:
            "iceElemental"
        case .fireElemental:
            "fireElemental"
        case .natureElemental:
            "natureElemental"
        case .sandDragon:
            "sandDragon"
        case .fireDragon:
            "fireDragon"
        case .classic:
            "classic"
        }
    }
    static func convertFromCoreData(string: String?) -> BattleModeModel {
        guard let string else {
            return .classic
        }
        return switch string {
            case "iceElemental":
                .iceElemental
            case "fireElemental":
                .fireElemental
            case "natureElemental":
                .natureElemental
            case "sandDragon":
                .sandDragon
            case "fireDragon":
                .fireDragon
            case "classic":
                .classic
            default:
                .classic
        }
    }
}

struct EnemyCharacterModel: Equatable {
    var assetName: String
    var characterName: String
    var isBoss: Bool
}
