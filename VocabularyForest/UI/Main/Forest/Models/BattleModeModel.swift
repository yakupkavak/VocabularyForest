//
//  BattleEnemyModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 1.12.2025.
//

enum BattleEnemyModel: Hashable, Codable {
    case iceElemental
    case fireElemental
    case natureElemental
    case sandDragon
    case fireDragon
    case classic
    
    var assetModels: [EnemyCharacterModel] {
        switch self {
        case .iceElemental:
            [EnemyCharacterModel(assetName: "IceElemental", characterName: "Buz Elementi", isBoss: true)]
        case .fireElemental:
            [EnemyCharacterModel(assetName: "FireElemental", characterName: "Ateş Elementi", isBoss: true)]
        case .natureElemental:
            [EnemyCharacterModel(assetName: "NatureElemental", characterName: "Doğa Elementi", isBoss: true)]
        case .sandDragon:
            [EnemyCharacterModel(assetName: "SandDragon", characterName: "Kum Ejderi", isBoss: true)]
        case .fireDragon:
            [EnemyCharacterModel(assetName: "FireDragon", characterName: "Ateş Ejderi", isBoss: true)]
        case .classic:
            [
                EnemyCharacterModel(assetName: "Skeleton", characterName: "İskelet", isBoss: false),
                EnemyCharacterModel(assetName: "Ghost", characterName: "Hayalet", isBoss: false),
                EnemyCharacterModel(assetName: "DarkKnight", characterName: "Kara şovalye", isBoss: false),
                EnemyCharacterModel(assetName: "BigKnight", characterName: "Asil Şovalye", isBoss: false),
                EnemyCharacterModel(assetName: "SkeletonDragon", characterName: "İskelet Ejderi", isBoss: false),
                EnemyCharacterModel(assetName: "Vampire", characterName: "Vampir", isBoss: true)
            ]
        }
    }
}

extension BattleEnemyModel {
    var title: String {
        switch self {
        case .iceElemental:
            "Buz Elementi"
        case .fireElemental:
            "Ateş Elementi"
        case .natureElemental:
            "Doğa Elementi"
        case .sandDragon:
            "Kum Ejderi"
        case .fireDragon:
            "Ateş Ejderi"
        case .classic:
            "Klasik"
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
    static func convertFromCoreData(string: String?) -> BattleEnemyModel {
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
