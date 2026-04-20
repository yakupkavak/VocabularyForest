//
//  DailyActivitiesModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.04.2026.
//

import Foundation

struct DailyActivitiesModel {
    let weeklyStreakLastClaimDate: Date?
    let weeklyStreakCurrentDay: Int
    let lastFetchDate: Date?
    let fixedTimeZone: String?
    let dailySpinLastUsedDate: Date?
    let lastUpdatedDate: Date
}
