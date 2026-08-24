//
//  RemoteForestChanges.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.08.2026.
//

import Foundation

/// Cloud-side winners of a delta sync, applied to CoreData in a single transaction.
/// Timestamps come from the cloud documents and must be written as-is; refreshing
/// them locally would make the next sync push the same data straight back.
struct RemoteForestChanges {
    var metadata: ForestMetadataUpdate?
    var trees: [TreeModel] = []
    var animals: [AnimalModel] = []
    var sculptures: [SculptureModel] = []
    var quests: [QuestTrackModel] = []
    var player: PlayerModel?
    var dailyActivities: DailyActivitiesModel?

    var isEmpty: Bool {
        metadata == nil && trees.isEmpty && animals.isEmpty && sculptures.isEmpty
            && quests.isEmpty && player == nil && dailyActivities == nil
    }
}

/// Forest-level economy fields synced on the main forest document.
struct ForestMetadataUpdate {
    let moneyValue: Int
    let diamondValue: Int
    let rainValue: Int
    let landHealthPercent: Int
    /// Chest pity open counters ride along with the balances under the same LWW timestamp
    let pityNatureOpenCount: Int
    let pityAntiqueOpenCount: Int
    let pityGeneralOpenCount: Int
    let lastUpdatedDate: Date
}
