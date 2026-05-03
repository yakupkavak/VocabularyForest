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
    private static let remoteQuestLock = NSLock()
    private static var remoteQuestTemplatesByType: [QuestType: [QuestModel]] = [:]
    
    static func updateRemoteQuestTemplates(_ templates: [QuestModel]) {
        remoteQuestLock.lock()
        remoteQuestTemplatesByType = Dictionary(grouping: templates, by: { $0.type })
        remoteQuestLock.unlock()
    }
    
    static func clearRemoteQuestTemplates() {
        remoteQuestLock.lock()
        remoteQuestTemplatesByType = [:]
        remoteQuestLock.unlock()
    }
    
    private static func remoteTemplates(for type: QuestType) -> [QuestModel]? {
        remoteQuestLock.lock()
        let templates = remoteQuestTemplatesByType[type]
        remoteQuestLock.unlock()
        return templates
    }
    
    // MARK: - Daily Quests
    
    func initalizeDailyQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .daily), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return [
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "A Sip of Water 💧"),
                description: String(localized: "Revive your memory: Repeat 5 old words and master them!"),
                reward: .water(count: 2),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .remainder,
                battleEnemyModel: .classic,
                gameLevel: .easy
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "Two Sips of Water 💧"),
                description: String(localized: "Revive your memory: Repeat 10 old words and master them!"),
                reward: .water(count: 10),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .remainder,
                battleEnemyModel: .iceElemental,
                gameLevel: .easy
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "Endless Water 💧"),
                description: String(localized: "Revive your memory: Repeat 20 old words and master them!"),
                reward: .water(count: 25),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 20,
                currentProgressCount: 0,
                questionType: .remainder,
                battleEnemyModel: .fireDragon,
                gameLevel: .easy
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "New Discoveries 🗺️"),
                description: String(localized: "The forest is expanding! Meet 5 new words and learn their meanings."),
                reward: .water(count: 2),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .easy
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "New Discoveries 2🗺️"),
                description: String(localized: "Meet 10 new words and learn their meanings."),
                reward: .water(count: 10),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 10,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .easy
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "New Discoveries 3🗺️"),
                description: String(localized: "Meet 20 new words and learn their meanings."),
                reward: .water(count: 25),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 20,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .easy
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "Gold Hunt 💰"),
                description: String(localized: "No hints, only victory! Pass 4 new words on your own merit."),
                reward: .gold(count: 4),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 4,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .natureElemental,
                gameLevel: .easy
            ),
            QuestModel(
                id: UUID(),
                type: .daily,
                title: String(localized: "Gold Hunt 2💰"),
                description: String(localized: "No hints, only victory! Pass 10 new words on your own merit."),
                reward: .gold(count: 10),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 10,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .classic,
                gameLevel: .easy
            ),
        ]
    }
    
    // MARK: - Weekly Quests
    
    func initalizeWeeklyQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .weekly), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return [
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: String(localized: "Chasing the Sunflower 🌻"),
                description: String(localized: "Defeat the Vampire 5 times and add that rare SunFlower to your collection."),
                reward: .plant(modelName: PlantReward.sunFlower.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .classic,
                gameLevel: .medium
            ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: String(localized: "Trail of the Blue Flame"),
                description: String(localized: "Bring the Fire Dragon to its knees 4 times, and the Blue Flame Bush is yours."),
                reward: .plant(modelName: PlantReward.blueFlameBush.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 4,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .fireDragon,
                gameLevel: .medium
            ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: String(localized: "Dance with Fire 🔥"),
                description: String(localized: "Defeat the Fire Elemental 5 times and earn the sacred Emberbud."),
                reward: .plant(modelName: PlantReward.emberbud.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .fireElemental,
                gameLevel: .medium
            ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: String(localized: "Ice Cold Victory ❄️"),
                description: String(localized: "Defeat the Ice Elemental 5 times, grab the Moon Bell!"),
                reward: .plant(modelName: PlantReward.moonBell.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .iceElemental,
                gameLevel: .medium
            ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: String(localized: "Crystal Reed Quest ✨"),
                description: String(localized: "Defeat the Nature Elemental 7 times and collect the glowing Crystal Reed!"),
                reward: .plant(modelName: PlantReward.crystalReed.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 7,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .natureElemental,
                gameLevel: .medium
            ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: String(localized: "Quest for the Desert Star 🌵"),
                description: String(localized: "Defeat the Sand Dragon 7 times and own the rare Desert Star Bloom!"),
                reward: .plant(modelName: PlantReward.desertStarBloom.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 7,
                currentProgressCount: 0,
                questionType: .remainder,
                battleEnemyModel: .sandDragon,
                gameLevel: .medium
            ),
        ]
    }
    
    // MARK: - Monthly Quests
    
    func initalizeMonthlyQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .monthly), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return [
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: String(localized: "Icy Paws ❄️"),
                description: String(localized: "The Ice Elemental froze the forest! Melt the ice with your words and save the cute cat."),
                reward: .animal(modelName: AnimalReward.cat.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 3,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .iceElemental,
                gameLevel: .hard
            ),
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: String(localized: "Fiery Friendship 🔥"),
                description: String(localized: "The Fire Dragon blocked the path! Defeat him with your wisdom and take the loyal dog with you."),
                reward: .animal(modelName: AnimalReward.dog.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 3,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .fireDragon,
                gameLevel: .hard
            ),
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: String(localized: "White Shadow ☁️"),
                description: String(localized: "A secret is hidden in the depths of the forest. Pass this tough test, reach the noble white cat."),
                reward: .animal(modelName: AnimalReward.whiteCat.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 3,
                currentProgressCount: 0,
                questionType: .remainder,
                battleEnemyModel: .classic,
                gameLevel: .hard
            )
        ]
    }
    
    // MARK: - Special Quests
    
    func initalizeSpecialQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .special), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return [
            QuestModel(
                id: UUID(),
                type: .special,
                title: String(localized: "Emerald Legend 🐉"),
                description: String(localized: "The Fire Dragon is furious! Quell this chaos and earn the legendary Emerald Dragon statue."),
                reward: .sculpture(modelName: SculptureReward.emeraldDragon.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 1,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .fireDragon,
                gameLevel: .insane
            ),
            QuestModel(
                id: UUID(),
                type: .special,
                title: String(localized: "Spirit of the Forest 🦌"),
                description: String(localized: "Only the wisest can see this deer. Are you ready for a battle that will challenge your mind?"),
                reward: .sculpture(modelName: SculptureReward.deer.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 1,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .classic,
                gameLevel: .insane
            ),
            QuestModel(
                id: UUID(),
                type: .special,
                title: String(localized: "Awakening of the Ancient Guardian 🗿"),
                description: String(localized: "The Sand Dragon protects the ancient ruins. Defeat him and add the Mossy Guardian statue to your collection!"),
                reward: .sculpture(modelName: SculptureReward.ancientLancer.name),
                lastUpdatedDate: Date(),
                status: .active,
                targetCount: 1,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .sandDragon,
                gameLevel: .insane
            )
        ]
    }
}
