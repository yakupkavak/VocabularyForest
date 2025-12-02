//
//  BattleModeModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 1.12.2025.
//

enum BattleModeModel {
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

struct EnemyCharacterModel: Equatable {
    var assetName: String
    var characterName: String
    var isBoss: Bool
}
