//
//  BattleConstant.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SwiftUI

// MARK: - CONSTANTS

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
    static let easyPlayerLevel = 3
    static let easyEnemyLevel = 3
    static let mediumPlayerLevel = 2
    static let mediumEnemyLevel = 10
    static let hardPlayerLevel = 2
    static let hardEnemyLevel = 20
    static let insanePlayerLevel = 3
    static let insaneEnemyLevel = 100
}

// MARK: - GAME UI HELPER MODELS

struct CharacterAnger {
    let totalLevel: Int
    var currentLevel: Int
    var name: String
    var imageFileName: String
}

enum GameLevel {
    case easy
    case medium
    case hard
    case insane
}

// MARK: - UI STATIONS

enum BattleUIStation {
    case chooseMagic
    case askQuestion
    case notDetermined
    case checkAnswer
}

enum QuestionStation {
    case correct
    case wrong
    case waiting
    case timeOut
    case notDetermined
}

// MARK: - ERROR MODEL

enum BattleError: Error {
    case emptyBookcase
    case emptyQuestionList
    case unexpectedError
    case emptyEnemyAsset
}

// MARK: - MAGIC MODELS

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

struct MagicSpeelModel: Hashable {
    var image: String
    var name: String
}
