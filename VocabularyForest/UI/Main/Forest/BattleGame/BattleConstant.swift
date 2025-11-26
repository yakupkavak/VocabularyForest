//
//  BattleConstant.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SwiftUI

enum BattleConstant {
    static let movingCharacterAnimation = "movingCharacterAnimation"
    static let movingCharacterAction = "movingCharacterAction"
    static let backgroundAction = "backgroundAnimation"
    static let airAction = "airAnimation"
    static let movingDistance: CGFloat = 100
    static let movingTimePerFrame: CGFloat = 0.1
    static let gameWidthSize = UIScreen.main.bounds.width * CGFloat(4)
    static let gameHeightSize = UIScreen.main.bounds.height
    static let characterPosition = UIScreen.main.bounds.height * CGFloat(0.3)
    static let enemySize = UIScreen.main.bounds.height * CGFloat(0.2)
    static let allMagicList: [MagicType] = [
        .fire, .darkMagic, .ice, .death, .psychic
    ]
}

struct MagicSpeelModel: Hashable {
    var image: String
    var name: String
}

enum MagicType: Hashable {
    case fire
    case darkMagic
    case ice
    case death
    case psychic
    
    var model: MagicSpeelModel {
        return switch self {
        case .fire:
            MagicSpeelModel(
                image: "fire_magic_icon",
                name: "Fire"
            )
        case .darkMagic:
            MagicSpeelModel(
                image: "dark_magic_icon",
                name: "Dark\nMagic"
            )
        case .ice:
            MagicSpeelModel(
                image: "ice_magic_icon",
                name: "Ice"
            )
        case .death:
            MagicSpeelModel(
                image: "death_magic_icon",
                name: "Death"
            )
        case .psychic:
            MagicSpeelModel(
                image: "psychic_magic_icon",
                name: "Psychic"
            )
        }
    }
}
