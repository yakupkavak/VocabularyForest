//
//  DailySpinRewards.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.04.2026.
//

import SwiftUI

enum AdventureReward: CaseIterable {
    case goldChest
    case antiqueChest
    case natureChest
    case diamondChest
    case gold
    case water
}

extension AdventureReward {
    var rewardCount: Int {
        return switch self {
        case .goldChest:
            1
        case .antiqueChest:
            1
        case .natureChest:
            1
        case .diamondChest:
            1
        case .gold:
            5
        case .water:
            10
        }
    }
    
    var image: String {
        return switch self {
        case .goldChest:
            ChestBountyModel.gold.rewardImage
        case .antiqueChest:
            ChestBountyModel.antique.rewardImage
        case .natureChest:
            ChestBountyModel.nature.rewardImage
        case .diamondChest:
            ChestBountyModel.diamond.rewardImage
        case .gold:
            QuestRewardModel.gold(count: 4).rewardImage
        case .water:
            QuestRewardModel.water(count: 4).rewardImage
        }
    }
    
    var name: String {
        return switch self {
        case .goldChest:
            ChestBountyModel.gold.rewardName
        case .antiqueChest:
            ChestBountyModel.antique.rewardName
        case .natureChest:
            ChestBountyModel.nature.rewardName
        case .diamondChest:
            ChestBountyModel.diamond.rewardName
        case .gold:
            String(localized: "Gold \(rewardCount)")
        case .water:
            String(localized: "Water \(rewardCount)")
        }
    }
    
    var textColor: Color {
        return switch self {
        case .goldChest:
            Color(hex: "#F2DA91")
        case .antiqueChest:
            Color(hex: "#F2F2F2")
        case .natureChest:
            Color(hex: "#B6D93B")
        case .diamondChest:
            Color(hex: "#025928")
        case .gold:
            Color(hex: "#D99B29")
        case .water:
            Color(hex: "#598EB2")
        }
    }
    
    var probabilityWeight: Double {
        return switch self {
        case .goldChest:
            3.0
        case .antiqueChest:
            1.0
        case .natureChest:
            1.0
        case .diamondChest:
            1.0
        case .gold:
            5.0
        case .water:
            5.0
        }
    }
    
    // MARK: - Dynamic Gradient Backgrounds
    
    var gradientBackground: AnyView {
        let colors: [Color]

        switch self {
        case .goldChest:
            colors = [
                Color(hex: "#F2DA91"),
                Color(hex: "#027333"),
                Color(hex: "#8C6A3F"),
                Color(hex: "#F2DA91"),
            ]

        case .antiqueChest:
            colors = [
                Color(hex: "#593825"),
                Color(hex: "#BF8C60"),
                Color(hex: "#BFB3A8"),
            ]

        case .natureChest:
            colors = [
                Color(hex: "#EFF299"),
                Color(hex: "#5A7302"),
                Color(hex: "#B6D93B"),
                Color(hex: "#86A614"),
            ]

        case .diamondChest:
            colors = [
                Color(hex: "#EAFAFC"),
                Color(hex: "#C6EFF5"),
                Color(hex: "#90D9E3"),
                Color(hex: "#53B7C6"),
                Color(hex: "#1E687A")
            ]

        case .gold:
            colors = [
                Color(hex: "#FBF1CB"),
                Color(hex: "#E5C77D"),
                Color(hex: "#EEC94B"),
                Color(hex: "#C5963C"),
                Color(hex: "#6C673C")
            ]

        case .water:
            colors = [
                Color(hex: "#E2F5FA"),
                Color(hex: "#9AC0DE"),
                Color(hex: "#77AFCA"),
                Color(hex: "#4D819D"),
                Color(hex: "#24475E")
            ]
        }

        return AnyView(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
