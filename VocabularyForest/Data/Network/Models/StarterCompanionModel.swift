//
//  StarterCompanionModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.05.2026.
//

import Foundation

struct StarterCompanionModel: Codable, Identifiable, Hashable {
    let id: String
    let modelKey: String
    let category: String
    let displayName: String?
    let previewImageName: String?
    let mediaSourceType: RewardMediaSourceType
    let mediaFileType: RewardMediaFileType
    let previewImageURL: String?
    let sourceFieldKey: String?
    let sourceVersion: String?
}
