//
//  AnnouncementModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 30.03.2026.
//

import Foundation

struct AnnouncementItem: Identifiable {
    let id = UUID()
    let title: String
    let image: ImageResource
    let type: AnnouncementTypeModel
}

enum AnnouncementTypeModel: Hashable {
    case tasks
    case dailyReward
    case dailySpin
    case adventureRoad
}
