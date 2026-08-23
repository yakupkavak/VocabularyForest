//
//  ConfigParametersList.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

struct ConfigParametersList: Decodable {
    let adventureRoadConfigVersion: String?
    let chestRewardsConfigVersion: String?
    let dailySpinRewardsConfigVersion: String?
    let gameEconomyConfigVersion: String?
    let marketConfigVersion: String?
    let questsConfigVersion: String?
    let weeklyRewardsConfigVersion: String?
    let rewardsConfigVersion: String?
}
