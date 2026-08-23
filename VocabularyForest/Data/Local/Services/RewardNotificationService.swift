//
//  RewardNotificationService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.07.2026.
//

import Foundation
import UserNotifications

// MARK: - REWARD NOTIFICATION SERVICE PROTOCOL

protocol RewardNotificationServiceProtocol {
    /// Schedules local notifications for unclaimed / upcoming rewards. Call when the app moves to the background.
    func scheduleRewardNotifications() async
    /// Removes all pending reward notifications. Call when the app becomes active again.
    func cancelRewardNotifications()
}

// MARK: - REWARD NOTIFICATION SERVICE

final class RewardNotificationService {
    
    // MARK: - CONSTANTS
    
    private enum NotificationID {
        static let unclaimedCombined = "reward_unclaimed_combined"
        static let dailySpinReady = "reward_daily_spin_ready"
        static let weeklyRewardReady = "reward_weekly_ready"
        
        static var all: [String] {
            [unclaimedCombined, dailySpinReady, weeklyRewardReady]
        }
    }
    
    /// Reminder delay for rewards that are already claimable when the user leaves the app.
    private let unclaimedReminderDelay: TimeInterval = 3 * 60 * 60
    /// Earliest hour a reward notification may fire (avoid waking the user at night).
    private let earliestFireHour = 9
    /// Latest hour a reward notification may fire.
    private let latestFireHour = 22
    
    // MARK: - PROPERTIES
    
    private let center = UNUserNotificationCenter.current()
    private let forestManager: ForestDataManagerProtocol
    private let adventureRoadService: AdventureRoadServiceProtocol
    
    // MARK: - INIT
    
    init(forestManager: ForestDataManagerProtocol, adventureRoadService: AdventureRoadServiceProtocol) {
        self.forestManager = forestManager
        self.adventureRoadService = adventureRoadService
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension RewardNotificationService: RewardNotificationServiceProtocol {
    
    func scheduleRewardNotifications() async {
        cancelRewardNotifications()
        
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        
        let now = Date()
        
        scheduleUnclaimedReminderIfNeeded(now: now)
        scheduleDailySpinNotification(now: now)
        scheduleWeeklyRewardReadyNotification(now: now)
    }
    
    func cancelRewardNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: NotificationID.all)
    }
}

// MARK: - UNCLAIMED REWARD CHECKS

private extension RewardNotificationService {
    
    enum UnclaimedReward {
        case weeklyReward
        case adventureRoad
        case quest
        
        var title: String {
            switch self {
            case .weeklyReward: String(localized: "notif_reward_weekly_ready_title")
            case .adventureRoad: String(localized: "notif_reward_adventure_ready_title")
            case .quest: String(localized: "notif_reward_quest_ready_title")
            }
        }
        
        var body: String {
            switch self {
            case .weeklyReward: String(localized: "notif_reward_weekly_ready_body")
            case .adventureRoad: String(localized: "notif_reward_adventure_ready_body")
            case .quest: String(localized: "notif_reward_quest_ready_body")
            }
        }
    }
    
    /// Collects everything that is claimable right now and schedules a single reminder for them.
    /// The daily spin is intentionally excluded: it resets on its own 24h after use,
    /// so it is handled by `scheduleDailySpinNotification` instead.
    func scheduleUnclaimedReminderIfNeeded(now: Date) {
        var unclaimed: [UnclaimedReward] = []
        
        if isWeeklyRewardClaimable(now: now) { unclaimed.append(.weeklyReward) }
        if hasReadyAdventureMilestone() { unclaimed.append(.adventureRoad) }
        if hasCompletedUnclaimedQuest() { unclaimed.append(.quest) }
        
        guard !unclaimed.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        if unclaimed.count == 1, let reward = unclaimed.first {
            content.title = reward.title
            content.body = reward.body
        } else {
            content.title = String(localized: "notif_reward_multiple_ready_title")
            content.body = String(localized: "notif_reward_multiple_ready_body")
        }
        content.sound = .default
        
        let fireDate = clampToAllowedHours(now.addingTimeInterval(unclaimedReminderDelay))
        schedule(id: NotificationID.unclaimedCombined, content: content, fireDate: fireDate, now: now)
    }
    
    func isWeeklyRewardClaimable(now: Date) -> Bool {
        guard let lastClaim = fetchDailyActivities()?.weeklyStreakLastClaimDate else { return true }
        return !fixedCalendar().isDate(lastClaim, inSameDayAs: now)
    }
    
    func hasReadyAdventureMilestone() -> Bool {
        guard let rows = adventureRoadService.adventureScreenModel?.rows else { return false }
        return rows.contains { $0.leftMilestone.status == .ready || $0.rightMilestone.status == .ready }
    }
    
    func hasCompletedUnclaimedQuest() -> Bool {
        guard let tracks = forestManager.fetchQuestTracks(contextType: .background).data else { return false }
        return tracks.contains { $0.status == .completed }
    }
}

// MARK: - UPCOMING REWARD SCHEDULING

private extension RewardNotificationService {
    
    /// The spin resets on its own 24h after the last use, so a single notification covers both cases:
    /// - cooldown still running → fire when it expires ("the spin is back")
    /// - already claimable → fire after the reminder delay ("the spin is waiting")
    func scheduleDailySpinNotification(now: Date) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        let fireDate: Date
        let lastUsed = fetchDailyActivities()?.dailySpinLastUsedDate
        
        if let targetDate = lastUsed?.addingTimeInterval(86400), targetDate > now {
            content.title = String(localized: "notif_reward_spin_available_title")
            content.body = String(localized: "notif_reward_spin_available_body")
            fireDate = targetDate
        } else {
            content.title = String(localized: "notif_reward_spin_ready_title")
            content.body = String(localized: "notif_reward_spin_ready_body")
            fireDate = now.addingTimeInterval(unclaimedReminderDelay)
        }
        
        schedule(id: NotificationID.dailySpinReady, content: content, fireDate: clampToAllowedHours(fireDate), now: now)
    }
    
    /// Fires when the next weekly streak day unlocks (midnight in the frozen timezone) while the app is closed.
    func scheduleWeeklyRewardReadyNotification(now: Date) {
        guard let lastClaim = fetchDailyActivities()?.weeklyStreakLastClaimDate else { return }
        
        let calendar = fixedCalendar()
        guard calendar.isDate(lastClaim, inSameDayAs: now),
              let nextDayStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)),
              nextDayStart > now else { return }
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_reward_weekly_available_title")
        content.body = String(localized: "notif_reward_weekly_available_body")
        content.sound = .default
        
        let fireDate = clampToAllowedHours(nextDayStart)
        schedule(id: NotificationID.weeklyRewardReady, content: content, fireDate: fireDate, now: now)
    }
}

// MARK: - HELPERS

private extension RewardNotificationService {
    
    func fetchDailyActivities() -> DailyActivitiesModel? {
        forestManager.fetchSafeForest(contextType: .background).data?.dailyActivities
    }
    
    func fixedCalendar() -> Calendar {
        var calendar = Calendar.current
        let identifier = fetchDailyActivities()?.fixedTimeZone ?? TimeZone.current.identifier
        calendar.timeZone = TimeZone(identifier: identifier) ?? TimeZone.current
        return calendar
    }
    
    /// Keeps notifications inside daytime hours; anything outside is pushed to the next allowed morning.
    func clampToAllowedHours(_ date: Date) -> Date {
        let calendar = fixedCalendar()
        let hour = calendar.component(.hour, from: date)
        
        if hour < earliestFireHour {
            return calendar.date(bySettingHour: earliestFireHour, minute: 0, second: 0, of: date) ?? date
        }
        if hour >= latestFireHour {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date),
                  let morning = calendar.date(bySettingHour: earliestFireHour, minute: 0, second: 0, of: tomorrow) else { return date }
            return morning
        }
        return date
    }
    
    func schedule(id: String, content: UNMutableNotificationContent, fireDate: Date, now: Date) {
        let interval = fireDate.timeIntervalSince(now)
        guard interval > 60 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
