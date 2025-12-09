//
//  ForestGameHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.11.2025.
//

import Foundation

protocol ForestGameHelperProtocol {
    func initalizeDailyQuests() -> [QuestModel]
    func initalizeWeeklyQuests() -> [QuestModel]
    func initalizeMonthlyQuests() -> [QuestModel]
    func initalizeSpecialQuests() -> [QuestModel]
}

struct ForestGameHelper: ForestGameHelperProtocol {
    func initalizeDailyQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .daily,
                title: "Memory Refresh",
                description: "Water your memory: master 5 old words!",
                reward: .water(count: 2),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .remainder,
                battleEnemyModel: .classic,
                gameLevel: .easy,
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: "Fun New Words",
                description: "Meet 5 new words and learn their meaning!",
                reward: .water(count: 2),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .easy,
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: "Wild Challenge",
                description: "No hints, big glory: beat 4 new words!",
                reward: .water(count: 4),
                status: .active,
                targetCount: 4,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .classic,
                gameLevel: .easy,
            ),
        ]
    }
    func initalizeWeeklyQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Moonflower Hunt",
                description: "Defeat the vampire 5 times and claim the sacred Moonflower.",
                reward: .plant(name: "SunFlower"),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .medium,
                ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Normal seviye Ateş Ejderini alt et",
                description: "Defeat the Fire Dragon 5 times and claim the sacred Blueflame Bush.",
                reward: .plant(name: "BlueflameBush"),
                status: .active,
                targetCount: 7,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .fireDragon,
                gameLevel: .medium,
                ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Normal seviye Vampir'i alt et",
                description: "Defeat the Fire Elemental 5 times and claim the sacred Emberbud.",
                reward: .plant(name: "Emberbud"),
                status: .active,
                targetCount: 2,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .fireElemental,
                gameLevel: .medium,
                ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Normal seviye Vampir'i alt et",
                description: "Defeat the Ice Elemental 5 times and claim the sacred Moonbell Flower.",
                reward: .plant(name: "Moonbell"),
                status: .active,
                targetCount: 7,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .iceElemental,
                gameLevel: .medium,
                ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Normal seviye Vampir'i alt et",
                description: "Vampiri alt edip ay çiçeğini elde edelim",
                reward: .plant(name: "CrystalReed"),
                status: .active,
                targetCount: 7,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .natureElemental,
                gameLevel: .medium,
                ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Normal seviye Vampir'i alt et",
                description: "Vampiri alt edip ay çiçeğini elde edelim",
                reward: .plant(name: "DesertStarBloom"),
                status: .active,
                targetCount: 7,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .sandDragon,
                gameLevel: .medium,
                ),
        ]
    }
    func initalizeMonthlyQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: "Aylık tazeleyelim",
                description: "Hafızamızı kısa temizleyelim, 5 kelimeyi doğru bilelim.",
                reward: .water(count: 2),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .easy,
                ),
        ]
    }
    func initalizeSpecialQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .special,
                title: "Special tazeleyelim",
                description: "Hafızamızı kısa temizleyelim, 5 kelimeyi doğru bilelim.",
                reward: .water(count: 2),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .easy,
                ),
        ]
    }
}

