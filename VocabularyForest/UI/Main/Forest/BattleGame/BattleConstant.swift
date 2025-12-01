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
    static let mediumPlayerLevel = 10
    static let mediumEnemyLevel = 2
    static let hardPlayerLevel = 20
    static let hardEnemyLevel = 2
    static let insanePlayerLevel = 100
    static let insaneEnemyLevel = 3
}

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let enemy: UInt32 = 0x1 << 0
    static let blackHole: UInt32 = 0x1 << 1   
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
    
    var playerLevel: Int {
        return switch self {
        case .easy:
            BattleConstant.easyPlayerLevel
        case .medium:
            BattleConstant.mediumPlayerLevel
        case .hard:
            BattleConstant.hardPlayerLevel
        case .insane:
            BattleConstant.insanePlayerLevel
        }
    }
    
    var enemyLevel: Int {
        return switch self {
        case .easy:
            BattleConstant.easyEnemyLevel
        case .medium:
            BattleConstant.mediumEnemyLevel
        case .hard:
            BattleConstant.hardEnemyLevel
        case .insane:
            BattleConstant.insaneEnemyLevel
        }
    }
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
