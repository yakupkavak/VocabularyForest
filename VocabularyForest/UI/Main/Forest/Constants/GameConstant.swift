//
//  ForestConstant.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.12.2025.
//

import UIKit

enum GameConstant {
    static let marketAnimation = "marketAnimation"
    static let adventureGateAnimation = "adventureGateAnimation"
    static let waitingCharacterAnimation = "waitingCharacterAnimation"
    static let movingCharacterAnimation = "movingCharacterAnimation"
    static let movingCharacterAction = "movingCharacterAction"
    static let jumpAnimation = "jumpAnimation"
    static let deathCharacterAnimation = "deathCharacterAnimation"
    static let deathCharacterAction = "deathCharacterAction"
    static let backgroundAction = "backgroundAnimation"
    static let attackAnimation = "attackAnimation"
    static let airAction = "airAnimation"
    static let rainAnimation = "rainAnimation"
    static let announcementAnimation = "announcementAnimation"
    static let movingDistance: CGFloat = 100
    static let movingTimePerFrame: CGFloat = 0.1
    static let attackTimePerFrame: CGFloat = 0.2
    static let waitingTimePerFrame: CGFloat = 0.1
    static let jumpTimePerFrame: CGFloat = 0.1
    static let dyingTimePerFrame: CGFloat = 0.4
    static let dyingTime: Double = 1.2
    static let gameWidthSize = UIScreen.main.bounds.width * CGFloat(4)
    static let gameHeightSize = UIScreen.main.bounds.height
    static let floorHeightSize = UIScreen.main.bounds.height * CGFloat(0.4)
    static let materialHeightSize = UIScreen.main.bounds.height * CGFloat(0.4) * CGFloat(0.6)
    static let sculptureHeightSize = UIScreen.main.bounds.height * CGFloat(0.4) * CGFloat(0.35)
    static let magicSize = CGSize(width: gameHeightSize * 0.2, height: gameHeightSize * 0.2)
    static let marketSize = CGSize(width: gameHeightSize * 0.2, height: gameHeightSize * 0.2)
    // Matches the 576x609 adventure_gate sprite frame aspect ratio
    static let adventureGateSize = CGSize(width: gameHeightSize * 0.2 * (576.0 / 609.0), height: gameHeightSize * 0.2)
    // Matches the 334x377 forest_announcement sprite frame aspect ratio
    static let announcementSignSize = CGSize(width: gameHeightSize * 0.2 * (334.0 / 377.0), height: gameHeightSize * 0.2)
    static let flyTime: Double = 1.0
    static let explodeTime: Double = 0.6
    static let walkingTime: Double = 1.5
}

enum HorizontalDirection {
    case right
    case left
}

enum Directions {
    case up, down
    case right,left
}

struct DirectionWithCount{
    var direction: Directions
    var count: Int
}
