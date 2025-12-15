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
    
    // MARK: - Daily Quests
    
    func initalizeDailyQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .daily,
                title: "Bir Yudum Su 💧",
                description: "Hafızanı canlandır: 5 eski kelimeyi tekrar et ve ustalaş!",
                reward: .water(count: 2),
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
                title: "Yeni Keşifler 🗺️",
                description: "Orman genişliyor! 5 yeni kelimeyle tanış ve anlamlarını öğren.",
                reward: .water(count: 2),
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
                title: "Altın Avı 💰",
                description: "İpucu yok, sadece zafer var! 4 yeni kelimeyi bileğinin hakkıyla geç.",
                reward: .gold(count: 4),
                status: .active,
                targetCount: 4,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .classic,
                gameLevel: .easy
            ),
        ]
    }
    
    // MARK: - Weekly Quests
    
    func initalizeWeeklyQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Güneş Çiçeği Peşinde 🌻",
                description: "Vampiri 5 kez alt et ve o nadide Güneş Çiçeği'ni koleksiyonuna kat.",
                reward: .plant(name: "SunFlower"),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .learning,
                battleEnemyModel: .classic,
                gameLevel: .medium
            ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Mavi Alevin İzinde",
                description: "Ateş Ejderhası'nı 4 kez dize getir, Mavi Alev Çalısı senin olsun.",
                reward: .plant(name: "BlueFlameBush"),
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
                title: "Ateşle Dans 🔥",
                description: "Ateş Elementini 5 kez yen ve kutsal Köz Tomurcuğu'nu kazan.",
                reward: .plant(name: "Emberbud"),
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
                title: "Buz Gibi Zafer ❄️",
                description: "Buz Elementini 5 kez mağlup et, Ay Çanı Çiçeği'ni kap!",
                reward: .plant(name: "MoonBell"),
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
                title: "Kristal Sazlık Görevi ✨",
                description: "Doğa Elementini 7 defa alt et ve parlayan Kristal Sazlığı topla!",
                reward: .plant(name: "CrystalReed"),
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
                title: "Çöl Yıldızı Arayışı 🌵",
                description: "Kum Ejderhasını 7 kez yen ve nadir bulunan Çöl Yıldızı Çiçeği'ne sahip ol!",
                reward: .plant(name: "DesertStarBloom"),
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
        return [
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: "Buzdan Patiler ❄️",
                description: "Buz Elementi ormanı dondurdu! Kelimelerinle buzları çöz ve sevimli kediyi kurtar.",
                reward: .animal(name: "Cat"),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .iceElemental,
                gameLevel: .hard
            ),
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: "Alevli Dostluk 🔥",
                description: "Ateş Ejderhası yolu kesti! Onu bilgeliğinle yen ve sadık köpeği yanına al.",
                reward: .animal(name: "Dog"),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .fireDragon,
                gameLevel: .hard
            ),
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: "Beyaz Gölge ☁️",
                description: "Ormanın derinliklerinde bir sır saklı. Bu zorlu sınavı geç, asil beyaz kediye ulaş.",
                reward: .animal(name: "WhiteCat"),
                status: .active,
                targetCount: 5,
                currentProgressCount: 0,
                questionType: .competitive,
                battleEnemyModel: .classic,
                gameLevel: .hard
            )
        ]
    }
    
    // MARK: - Special Quests
    
    func initalizeSpecialQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .special,
                title: "Zümrüt Efsanesi 🐉",
                description: "Ateş Ejderhası çok öfkeli! Bu kaosu dindir ve efsanevi Zümrüt Ejderha heykelini hak et.",
                reward: .sculpture(name: "EmeraldDragon"),
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
                title: "Ormanın Ruhu 🦌",
                description: "Sadece en bilgeler bu geyiği görebilir. Zihnini zorlayacak bir savaşa hazır mısın?",
                reward: .sculpture(name: "Deer"),
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
                title: "Kadim Muhafızın Uyanışı 🗿",
                description: "Kum Ejderhası antik harabeleri koruyor. Onu yen ve Yosunlu Muhafız heykelini koleksiyonuna kat!",
                reward: .sculpture(name: "AncientLancer"),
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
