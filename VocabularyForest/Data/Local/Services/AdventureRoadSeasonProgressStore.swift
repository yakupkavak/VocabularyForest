//
//  AdventureRoadSeasonProgressStore.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.04.2026.
//

import Foundation
internal import CoreData

protocol AdventureRoadSeasonProgressStoreProtocol: AnyObject {
    func applySeasonUpdate(seasonID: String, resetProgress: Bool)
}

final class AdventureRoadSeasonProgressStore: AdventureRoadSeasonProgressStoreProtocol {
    private let coreDataManager: CoreDataManagerProtocol
    private let forestDataManager: ForestDataManagerProtocol

    init(
        coreDataManager: CoreDataManagerProtocol,
        forestDataManager: ForestDataManagerProtocol
    ) {
        self.coreDataManager = coreDataManager
        self.forestDataManager = forestDataManager
    }

    func applySeasonUpdate(seasonID: String, resetProgress: Bool) {
        let context = coreDataManager.viewContext

        context.performAndWait {
            guard let forest = forestDataManager.getCurrentForest(context: context),
                  let dailyActivities = forest.dailyActivities else {
                return
            }

            dailyActivities.adventureSeasonID = seasonID
            dailyActivities.lastUpdatedDate = Date()

            if resetProgress {
                dailyActivities.monthlyLongLearnedCount = 0
                dailyActivities.monthlyShortLearnedCount = 0
                dailyActivities.claimedLongTiers = nil
                dailyActivities.claimedShortTiers = nil
            }

            coreDataManager.save(in: context)
        }
    }
}
