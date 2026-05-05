//
//  PlayerHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import Foundation

struct PlayerHelper {
    static func createDefaultPlayer() -> PlayerModel {
        PlayerModel(name: String(localized: "Ichigo"), lastUpdateDate: Date())
    }
}
