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
    
    var assetModels: [String] {
        switch self {
        case .iceElemental:
            ["IceElemental"]
        case .fireElemental:
            ["FireElemental"]
        case .natureElemental:
            ["NatureElemental"]
        case .sandDragon:
            ["SandDragon"]
        case .fireDragon:
            ["FireDragon"]
        case .classic:
            ["Vampire","Vampire"] // TODO: - ADD NEW ENEMIES
        }
    }
}
