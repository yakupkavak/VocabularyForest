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
    private struct ChestRuntimeConfig {
        let goldDiamondChance: Int
        let goldWaterChance: Int
        let natureAnimalChance: Int
        let antiqueAnimalChance: Int
        let goldMin: Int
        let goldMax: Int
        let bonusDiamondMin: Int
        let bonusDiamondMax: Int
        let bonusWaterMin: Int
        let bonusWaterMax: Int
        let diamondChestMin: Int
        let diamondChestMax: Int
    }

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
    
    static func getBackgroundGradient(reward: LocalRewardType) -> RadialGradient {
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
        let config = chestRuntimeConfig()
        switch chest {
        case .gold:
            let roll = Int.random(in: 0..<RandomConfig.percentScale)
            let waterThreshold = config.goldDiamondChance + config.goldWaterChance
            if roll < config.goldDiamondChance {
                return .diamond(count: Int.random(in: config.bonusDiamondMin...config.bonusDiamondMax))
            }
            if roll < waterThreshold {
                return .water(count: Int.random(in: config.bonusWaterMin...config.bonusWaterMax))
            }
            return .gold(count: Int.random(in: config.goldMin...config.goldMax))
            
        case .nature:
            let roll = Int.random(in: 0..<RandomConfig.percentScale)
            if roll < config.natureAnimalChance {
                let animal = AnimalReward.allCases.randomElement() ?? .dog
                return .animal(modelName: animal.name)
            }
            let plant = PlantReward.allCases.randomElement() ?? .sunFlower
            return .plant(modelName: plant.name)
            
        case .diamond:
            return .diamond(count: Int.random(in: config.diamondChestMin...config.diamondChestMax))
            
        case .antique:
            let roll = Int.random(in: 0..<RandomConfig.percentScale)
            if roll < config.antiqueAnimalChance {
                let animal = AnimalReward.allCases.randomElement() ?? .dog
                return .animal(modelName: animal.name)
            }
            let sculpture = SculptureReward.allCases.randomElement() ?? .deer
            return .sculpture(modelName: sculpture.name)
        }
    }
    
    static func convertDailyRewardModel(from rewardModel: SpinModel) -> LocalRewardType {
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
    
    static func defaultDailySpinRewards() -> [DailySpinModel] {
        AdventureReward.allCases
            .filter { $0 != .diamondChest }
            .map { reward in
                switch reward {
                case .goldChest:
                    DailySpinModel(weight: reward.probabilityWeight, reward: .chest(model: .gold))
                case .antiqueChest:
                    DailySpinModel(weight: reward.probabilityWeight, reward: .chest(model: .antique))
                case .natureChest:
                    DailySpinModel(weight: reward.probabilityWeight, reward: .chest(model: .nature))
                case .diamondChest:
                    DailySpinModel(weight: reward.probabilityWeight, reward: .chest(model: .diamond))
                case .gold:
                    DailySpinModel(weight: reward.probabilityWeight, reward: .standart(model: .gold(count: reward.rewardCount)))
                case .water:
                    DailySpinModel(weight: reward.probabilityWeight, reward: .standart(model: .water(count: reward.rewardCount)))
                }
            }
    }
    
    static func createDailySpinWheel(from rewards: [DailySpinModel]) -> ([SpinModel], [Int: LocalRewardType]) {
        let safeRewards = rewards.isEmpty ? defaultDailySpinRewards() : rewards
        var rewardMap: [Int: LocalRewardType] = [:]
        
        let spinModels = safeRewards.enumerated().map { index, model in
            let id = index + 1
            rewardMap[id] = model.reward
            return SpinModel(
                id: id,
                text: spinText(for: model.reward),
                image: Image(model.reward.rewardImage),
                weight: max(1.0, model.weight),
                textColor: spinTextColor(for: model.reward),
                background: spinBackground(for: model.reward)
            )
        }
        return (spinModels, rewardMap)
    }

}

private extension RewardHelper {
    static func spinText(for reward: LocalRewardType) -> String {
        switch reward {
        case .chest(let model):
            return model.rewardName
        case .standart(let model):
            switch model {
            case .gold(let count):
                return String(localized: "Gold \(count)")
            case .water(let count):
                return String(localized: "Water \(count)")
            case .diamond(let count):
                return String(localized: "Diamond \(count)")
            case .animal, .plant, .sculpture:
                return String(localized: String.LocalizationValue(model.rewardName))
            }
        }
    }
    
    static func spinTextColor(for reward: LocalRewardType) -> Color {
        switch reward {
        case .chest(let model):
            switch model {
            case .gold:
                return Color(hex: "#F2DA91")
            case .antique:
                return Color(hex: "#F2F2F2")
            case .nature:
                return Color(hex: "#B6D93B")
            case .diamond:
                return Color(hex: "#025928")
            }
        case .standart(let model):
            switch model {
            case .gold:
                return Color(hex: "#D99B29")
            case .water:
                return Color(hex: "#598EB2")
            case .diamond:
                return Color(hex: "#53B7C6")
            case .animal, .plant:
                return Color(hex: "#B6D93B")
            case .sculpture:
                return Color(hex: "#BFB3A8")
            }
        }
    }
    
    static func spinBackground(for reward: LocalRewardType) -> AnyView {
        let colors: [Color]
        
        switch reward {
        case .chest(let model):
            switch model {
            case .gold:
                colors = [Color(hex: "#F2DA91"), Color(hex: "#027333"), Color(hex: "#8C6A3F"), Color(hex: "#F2DA91")]
            case .antique:
                colors = [Color(hex: "#593825"), Color(hex: "#BF8C60"), Color(hex: "#BFB3A8")]
            case .nature:
                colors = [Color(hex: "#EFF299"), Color(hex: "#5A7302"), Color(hex: "#B6D93B"), Color(hex: "#86A614")]
            case .diamond:
                colors = [Color(hex: "#EAFAFC"), Color(hex: "#C6EFF5"), Color(hex: "#90D9E3"), Color(hex: "#53B7C6"), Color(hex: "#1E687A")]
            }
        case .standart(let model):
            switch model {
            case .gold:
                colors = [Color(hex: "#FBF1CB"), Color(hex: "#E5C77D"), Color(hex: "#EEC94B"), Color(hex: "#C5963C"), Color(hex: "#6C673C")]
            case .water:
                colors = [Color(hex: "#E2F5FA"), Color(hex: "#9AC0DE"), Color(hex: "#77AFCA"), Color(hex: "#4D819D"), Color(hex: "#24475E")]
            case .diamond:
                colors = [Color(hex: "#EAFAFC"), Color(hex: "#90D9E3"), Color(hex: "#53B7C6"), Color(hex: "#1E687A")]
            case .animal, .plant:
                colors = [Color(hex: "#EFF299"), Color(hex: "#B6D93B"), Color(hex: "#5A7302")]
            case .sculpture:
                colors = [Color(hex: "#BFB3A8"), Color(hex: "#BF8C60"), Color(hex: "#593825")]
            }
        }
        
        return AnyView(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private static func chestRuntimeConfig() -> ChestRuntimeConfig {
        guard let economyConfig = GameManager.snapshotEconomyConfig() else {
            return ChestRuntimeConfig(
                goldDiamondChance: RandomConfig.goldDiamondChance,
                goldWaterChance: RandomConfig.goldWaterChance,
                natureAnimalChance: RandomConfig.natureAnimalChance,
                antiqueAnimalChance: RandomConfig.antiqueAnimalChance,
                goldMin: RandomConfig.goldMin,
                goldMax: RandomConfig.goldMax,
                bonusDiamondMin: RandomConfig.bonusDiamondMin,
                bonusDiamondMax: RandomConfig.bonusDiamondMax,
                bonusWaterMin: RandomConfig.bonusWaterMin,
                bonusWaterMax: RandomConfig.bonusWaterMax,
                diamondChestMin: RandomConfig.diamondChestMin,
                diamondChestMax: RandomConfig.diamondChestMax
            )
        }
        
        let ranges = economyConfig.chestRewardRanges
        return ChestRuntimeConfig(
            goldDiamondChance: economyConfig.chestOdds.goldChestDiamondChance,
            goldWaterChance: economyConfig.chestOdds.goldChestWaterChance,
            natureAnimalChance: economyConfig.chestOdds.natureChestAnimalChance,
            antiqueAnimalChance: economyConfig.chestOdds.antiqueChestAnimalChance,
            goldMin: ranges.goldChestGoldMin,
            goldMax: ranges.goldChestGoldMax,
            bonusDiamondMin: ranges.goldChestDiamondMin,
            bonusDiamondMax: ranges.goldChestDiamondMax,
            bonusWaterMin: RandomConfig.bonusWaterMin,
            bonusWaterMax: RandomConfig.bonusWaterMax,
            diamondChestMin: ranges.diamondChestDiamondMin,
            diamondChestMax: ranges.diamondChestDiamondMax
        )
    }
}
