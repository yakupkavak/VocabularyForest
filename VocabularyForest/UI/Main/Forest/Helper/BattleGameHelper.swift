//
//  BattleGameHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.12.2025.
//

import Foundation

func calculateMinBookCount(
    battleMode: BattleEnemyModel,
    gameLevel: GameLevel,
) -> Int{
    var totalCorrectBook = 0
    var totalWrongBook = 0
    let assetModels = battleMode.assetModels
    for characterModel in assetModels {
        totalCorrectBook += characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel
        totalWrongBook += gameLevel.playerLevel
    }
    totalWrongBook += gameLevel.playerLevel
    return totalCorrectBook + totalWrongBook + 1
}
