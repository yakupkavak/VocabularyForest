//
//  BattleEnemyModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 1.12.2025.
//

internal import Foundation
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
            [EnemyCharacterModel(assetName: "IceElemental", characterName: String(localized: "Buz Elementi"), isBoss: true)]
        case .fireElemental:
            [EnemyCharacterModel(assetName: "FireElemental", characterName: String(localized: "Ateş Elementi"), isBoss: true)]
        case .natureElemental:
            [EnemyCharacterModel(assetName: "NatureElemental", characterName: String(localized: "Doğa Elementi"), isBoss: true)]
        case .sandDragon:
            [EnemyCharacterModel(assetName: "SandDragon", characterName: String(localized: "Kum Ejderi"), isBoss: true)]
        case .fireDragon:
            [EnemyCharacterModel(assetName: "FireDragon", characterName: String(localized: "Ateş Ejderi"), isBoss: true)]
        case .classic:
            [
                EnemyCharacterModel(assetName: "Skeleton", characterName: String(localized: "İskelet"), isBoss: false),
                EnemyCharacterModel(assetName: "Ghost", characterName: String(localized: "Hayalet"), isBoss: false),
                EnemyCharacterModel(assetName: "DarkKnight", characterName: String(localized: "Kara şovalye"), isBoss: false),
                EnemyCharacterModel(assetName: "BigKnight", characterName: String(localized: "Asil Şovalye"), isBoss: false),
                EnemyCharacterModel(assetName: "SkeletonDragon", characterName: String(localized: "İskelet Ejderi"), isBoss: false),
                EnemyCharacterModel(assetName: "Vampire", characterName: String(localized: "Vampir"), isBoss: true)
            ]
        }
    }
}

extension BattleEnemyModel {
    var title: String {
        switch self {
        case .iceElemental:
            String(localized: "Buz Elementi")
        case .fireElemental:
            String(localized: "Ateş Elementi")
        case .natureElemental:
            String(localized: "Doğa Elementi")
        case .sandDragon:
            String(localized: "Kum Ejderi")
        case .fireDragon:
            String(localized: "Ateş Ejderi")
        case .classic:
            String(localized: "Klasik")
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
