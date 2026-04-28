//
//  RewardHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.04.2026.
//

import SwiftUI
import YKSpinWheel

enum PlantReward: String, CaseIterable {
    case sunFlower = "SunFlower"
    case blueFlameBush = "BlueFlameBush"
    case emberbud = "Emberbud"
    case moonBell = "MoonBell"
    case crystalReed = "CrystalReed"
    case desertStarBloom = "DesertStarBloom"
    
    var name: String { rawValue }
    
    var localizedKey: String {
        switch self {
        case .sunFlower:
            "sun_flower_name"
        case .blueFlameBush:
            "blue_flame_bush_name"
        case .emberbud:
            "emberbud_name"
        case .moonBell:
            "moon_beel_name"
        case .crystalReed:
            "crystal_reed_name"
        case .desertStarBloom:
            "desert_star_bloom_name"
        }
    }
}

enum AnimalReward: String, CaseIterable {
    case cat = "Cat"
    case dog = "Dog"
    case whiteCat = "WhiteCat"
    
    var name: String { rawValue }
    
    var localizedKey: String {
        switch self {
        case .cat:
            "cat_name"
        case .dog:
            "dog_name"
        case .whiteCat:
            "white_cat_name"
        }
    }
}

enum SculptureReward: String, CaseIterable {
    case emeraldDragon = "EmeraldDragon"
    case deer = "Deer"
    case ancientLancer = "AncientLancer"
    
    var name: String { rawValue }
    
    var localizedKey: String {
        switch self {
        case .emeraldDragon:
            "emerald_dragon_name"
        case .deer:
            "ancient_deer_name"
        case .ancientLancer:
            "ancient_lancer"
        }
    }
}

extension RewardHelper {
    enum RandomConfig {
       static let percentScale = 100
       static let goldDiamondChance = 10
       static let goldWaterChance = 20
       static let natureAnimalChance = 20
       static let antiqueAnimalChance = 50
       
       static let goldMin = 50
       static let goldMax = 100
       static let bonusDiamondMin = 1
       static let bonusDiamondMax = 3
       static let bonusWaterMin = 30
       static let bonusWaterMax = 40
       static let diamondChestMin = 10
       static let diamondChestMax = 20
   }
}

struct RewardHelper {
    private enum BackgroundGradientConfig {
        static let startRadius: CGFloat = 30
        static let endRadius: CGFloat = 620
    }

    private enum BackgroundPalette {
        static let gold: [Color] = [
            Color(hex: "#FFF4C2"),
            Color(hex: "#F4C430"),
            Color(hex: "#B7791F")
        ]
        
        static let nature: [Color] = [
            Color(hex: "#EFF299"),
            Color(hex: "#B6D93B"),
            Color(hex: "#5A7302")
        ]
        
        static let diamond: [Color] = [
            Color(hex: "#EAFAFC"),
            Color(hex: "#53B7C6"),
            Color(hex: "#1E687A")
        ]
        
        static let antique: [Color] = [
            Color(hex: "#BFB3A8"),
            Color(hex: "#BF8C60"),
            Color(hex: "#593825")
        ]
    }
    
    // MARK: - BACKGROUND GRADIENT
    
    static func getBackgroundGradient(reward: LocalRewardModel) -> RadialGradient {
        let palette: [Color]
        switch reward {
        case .standart(let model):
            switch model {
            case .gold:
                palette = BackgroundPalette.gold
            case .water:
                palette = BackgroundPalette.diamond
            case .diamond:
                palette = BackgroundPalette.diamond
            case .plant:
                palette = BackgroundPalette.nature
            case .animal:
                palette = BackgroundPalette.nature
            case .sculpture:
                palette = BackgroundPalette.antique
            }
        case .chest(let model):
            switch model {
            case .gold:
                palette = BackgroundPalette.gold
            case .nature:
                palette = BackgroundPalette.nature
            case .diamond:
                palette = BackgroundPalette.diamond
            case .antique:
                palette = BackgroundPalette.antique
            }
        }
        return RadialGradient(
            gradient: Gradient(colors: [
                palette[0].opacity(0.86),
                palette[0].opacity(0.8),
                palette[1].opacity(0.74),
                palette[2].opacity(0.68),
                palette[2].opacity(0.62)
            ]),
            center: .center,
            startRadius: BackgroundGradientConfig.startRadius,
            endRadius: BackgroundGradientConfig.endRadius
        )
    }
    
    // MARK: - CHEST REWARD GENERATOR
    
    static func generateRandomReward(from chest: ChestBountyModel) -> QuestRewardModel {
        switch chest {
        case .gold:
            let roll = Int.random(in: 0..<RandomConfig.percentScale)
            let waterThreshold = RandomConfig.goldDiamondChance + RandomConfig.goldWaterChance
            if roll < RandomConfig.goldDiamondChance {
                return .diamond(count: Int.random(in: RandomConfig.bonusDiamondMin...RandomConfig.bonusDiamondMax))
            }
            if roll < waterThreshold {
                return .water(count: Int.random(in: RandomConfig.bonusWaterMin...RandomConfig.bonusWaterMax))
            }
            return .gold(count: Int.random(in: RandomConfig.goldMin...RandomConfig.goldMax))
            
        case .nature:
            let roll = Int.random(in: 0..<RandomConfig.percentScale)
            if roll < RandomConfig.natureAnimalChance {
                let animal = AnimalReward.allCases.randomElement() ?? .dog
                return .animal(modelName: animal.name)
            }
            let plant = PlantReward.allCases.randomElement() ?? .sunFlower
            return .plant(modelName: plant.name)
            
        case .diamond:
            return .diamond(count: Int.random(in: RandomConfig.diamondChestMin...RandomConfig.diamondChestMax))
            
        case .antique:
            let roll = Int.random(in: 0..<RandomConfig.percentScale)
            if roll < RandomConfig.antiqueAnimalChance {
                let animal = AnimalReward.allCases.randomElement() ?? .dog
                return .animal(modelName: animal.name)
            }
            let sculpture = SculptureReward.allCases.randomElement() ?? .deer
            return .sculpture(modelName: sculpture.name)
        }
    }
    
    static func convertDailyRewardModel(from rewardModel: SpinModel) -> LocalRewardModel {
        let spinRewards = AdventureReward.allCases.filter { $0 != .diamondChest }
        let safeIndex = max(0, min(rewardModel.id - 1, spinRewards.count - 1))
        let spinReward = spinRewards[safeIndex]

        switch spinReward {
        case .goldChest:
            return .chest(model: .gold)
        case .antiqueChest:
            return .chest(model: .antique)
        case .natureChest:
            return .chest(model: .nature)
        case .diamondChest:
            return .chest(model: .diamond)
        case .gold:
            return .standart(model: .gold(count: spinReward.rewardCount))
        case .water:
            return .standart(model: .water(count: spinReward.rewardCount))
        }
    }

}
