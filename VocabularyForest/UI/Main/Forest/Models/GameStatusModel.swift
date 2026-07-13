//
//  GameStatusModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.12.2025.
//

struct GameStatusModel {
    var trueCount: Int
    var wrongCount: Int
    var wrongWords: [BookModel]
    var userWon: Bool?
    var earnedGold: Int = 0
}
