//
//  QuestTrackModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.05.2026.
//

import Foundation

struct QuestTrackModel {
    let id: String
    let lastUpdateDate: Date
    let status: QuestStatus
    let currentProgressCount: Int
}
