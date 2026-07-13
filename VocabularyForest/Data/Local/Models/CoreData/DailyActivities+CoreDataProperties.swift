//
//  DailyActivities+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.04.2026.
//
//

public import Foundation
public import CoreData


public typealias DailyActivitiesCoreDataPropertiesSet = NSSet

extension DailyActivities {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyActivities> {
        return NSFetchRequest<DailyActivities>(entityName: "DailyActivities")
    }

    @NSManaged public var adventureSeasonID: String?
    @NSManaged public var claimedLongTiers: String?
    @NSManaged public var claimedShortTiers: String?
    @NSManaged public var dailyKillGoldCount: Int16
    @NSManaged public var dailySpinLastUsedDate: Date?
    @NSManaged public var killGoldLastResetDate: Date?
    @NSManaged public var fixedTimeZone: String?
    @NSManaged public var lastFetchDate: Date?
    @NSManaged public var lastUpdatedDate: Date?
    @NSManaged public var monthlyLongLearnedCount: Int16
    @NSManaged public var monthlyShortLearnedCount: Int16
    @NSManaged public var weeklyStreakCurrentDay: Int16
    @NSManaged public var weeklyStreakLastClaimDate: Date?

}

extension DailyActivities: ConvertSafeModel {
    typealias SafeModel = DailyActivitiesModel
    
    func safeObject(context: NSManagedObjectContext) throws -> DailyActivitiesModel {
        try context.performAndWait {
            if let lastUpdatedDate {
                return DailyActivitiesModel(
                    adventureSeasonID: adventureSeasonID,
                    claimedLongTiers: claimedLongTiers,
                    claimedShortTiers: claimedShortTiers,
                    monthlyLongLearnedCount: Int(monthlyLongLearnedCount),
                    monthlyShortLearnedCount: Int(monthlyShortLearnedCount),
                    weeklyStreakLastClaimDate: weeklyStreakLastClaimDate,
                    weeklyStreakCurrentDay: Int(weeklyStreakCurrentDay),
                    lastFetchDate: lastFetchDate,
                    fixedTimeZone: fixedTimeZone,
                    dailySpinLastUsedDate: dailySpinLastUsedDate,
                    lastUpdatedDate: lastUpdatedDate
                )
            }
            throw SafeModelError.emptyValue
        }
    }
}

extension DailyActivities : Identifiable {

}
