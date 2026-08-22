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
    static let announcementTimePerFrame: CGFloat = 0.08
    static let adventureGateTimePerFrame: CGFloat = 0.05
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
    static let adventureGateSize = CGSize(width: gameHeightSize * 0.2 * (576.0 / 609.0), height: gameHeightSize * 0.2)
    static let announcementSignSize = CGSize(width: gameHeightSize * 0.2 * (334.0 / 377.0), height: gameHeightSize * 0.2)
    static let flyTime: Double = 1.0
    static let explodeTime: Double = 0.6
    static let walkingTime: Double = 1.5
    static let scrollSpeedPerSecond: CGFloat = 100
    static let marketRevealScrollSeconds: CGFloat = 0.1
    static let adventureGateRevealScrollSeconds: CGFloat = 0.5
    /// Launch-time world-space X centers of the fixed structures (nodes are
    /// center-anchored on X). Single source shared by EnvironmentManager's
    /// sprite placement and ForestDataManager's random-spawn exclusion.
    static let marketCenterX = UIScreen.main.bounds.width
        + marketSize.width / 2
        + scrollSpeedPerSecond * marketRevealScrollSeconds
    static let adventureGateCenterX = -adventureGateSize.width / 2
        - scrollSpeedPerSecond * adventureGateRevealScrollSeconds
    static let announcementSignCenterX = UIScreen.main.bounds.width * ForestConstant.announcementSignRelativeX
    /// Spawned plants/sculptures are center-anchored and at most about one
    /// plantHeight wide, so half of it keeps their widest half clear of a band.
    static let structureSpawnMargin = ComponentSizeConstant.plantHeight / 2
    /// Horizontal bands occupied by the fixed structures, expressed in the
    /// Tree/Sculpture xPosition unit (fraction of gameWidthSize). Random
    /// spawn positions must land outside every band.
    static let reservedStructureXRanges: [ClosedRange<Double>] = [
        (marketCenterX, marketSize.width),
        (adventureGateCenterX, adventureGateSize.width),
        (announcementSignCenterX, announcementSignSize.width)
    ].map { center, width in
        let lowerBound = Double((center - width / 2 - structureSpawnMargin) / gameWidthSize)
        let upperBound = Double((center + width / 2 + structureSpawnMargin) / gameWidthSize)
        return lowerBound...upperBound
    }
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
