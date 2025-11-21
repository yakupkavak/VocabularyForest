//
//  ForestGameHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.11.2025.
//

import Foundation

protocol ForestGameHelperProtocol {
    func initalizeQuests() -> [QuestModel]
}

struct ForestGameHelper: ForestGameHelperProtocol {
    func initalizeQuests() -> [QuestModel] {
        return [
            QuestModel(
                id: UUID(),
                type: .daily,
                title: "Kelime Hatırla",
                description: "Hafızamızı kısa temizleyelim",
                reward: .water(count: 10),
                status: .active,
                targetCount: 10,
                currentProgressCount: 0
            ),
            QuestModel(
                id: UUID(),
                type: .weekly,
                title: "Ejderhayı Alt Et",
                description: "Hafızamızı kısa temizleyelim",
                reward: .plant(name: "zambak"),
                status: .active,
                targetCount: 10,
                currentProgressCount: 0
            ),
            QuestModel(
                id: UUID(),
                type: .monthly,
                title: "Aya Ulaş",
                description: "Hafızamızı kısa temizleyelim",
                reward: .animal(name: "lion"),
                status: .active,
                targetCount: 10,
                currentProgressCount: 0
            )
            ,QuestModel(
                id: UUID(),
                type: .special,
                title: "Toefl Alt Et",
                description: "Sınava hazır mısın?",
                reward: .sculpture(name: "toefl_sculpture"),
                status: .active,
                targetCount: 1,
                currentProgressCount: 0
            )]
    }
}

