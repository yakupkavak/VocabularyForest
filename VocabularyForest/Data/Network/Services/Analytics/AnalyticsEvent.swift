//
//  AnalyticsEvent.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.08.2026.
//

import FirebaseAnalytics
import Foundation

struct AnalyticsEventDescriptor {
    let name: String
    let parameters: [String: Any]
}

// Value alphabets are a binding contract with the Android mirror
// (docs/plans/2026-08-11-ios-google-analytics.md §5, §11) — do not rename raw values.

enum AnalyticsAuthMethod: String {
    case apple, google
}

enum BookcaseCreationSource: String {
    case manual, packet
}

enum PacketUnlockMethod: String {
    case free
    case rewardedAd = "rewarded_ad"
}

enum AnalyticsTrackingStatus: String {
    case authorized, denied, restricted
    case notDetermined = "not_determined"
}

enum CloudSyncResult: String {
    case success, conflict, failed
}

enum CloudSyncTrigger: String {
    case manual, auto
}

enum CloudRestoreChoice: String {
    case restore, dismiss
    case keepLocal = "keep_local"
}

enum AnalyticsPermissionStatus: String {
    case authorized, denied
}

/// Shared `reason` parameter values for failure events.
enum AnalyticsFailureReason {
    static let alreadyExist = "already_exist"
    static let missingFields = "missing_fields"
    static let network = "network"
}

/// `virtual_currency_name` parameter values.
enum AnalyticsVirtualCurrency {
    static let gold = "gold"
    static let diamond = "diamond"
}

/// `source` parameter values for `earn_virtual_currency`.
enum AnalyticsGoldSource {
    static let battleKill = "battle_kill"
    static let dailySpin = "daily_spin"
    static let weeklyReward = "weekly_reward"
    static let adventureRoad = "adventure_road"
    static let quest = "quest"
    static let market = "market"
    static let package = "package"
}

enum AnalyticsEvent {
    case tutorialBegin
    case onboardingStepViewed(stepIndex: Int)
    case tutorialComplete
    case login(method: AnalyticsAuthMethod)
    case signUp(method: AnalyticsAuthMethod)
    case attPromptResult(status: AnalyticsTrackingStatus)
    case bookcaseCreated(languagePair: String, source: BookcaseCreationSource)
    case bookcaseSelected(bookcaseID: String)
    case bookCreated(bookcaseID: String, hasExample: Bool)
    case bookEdited(bookcaseID: String)
    case bookDeleted(bookcaseID: String)
    case packetDownloadStarted(packetID: String, unlockMethod: PacketUnlockMethod)
    case packetDownloadCompleted(packetID: String, wordCount: Int)
    case packetDownloadFailed(packetID: String, reason: String)
    case dailyWordViewed
    case quizStarted(bookcaseID: String, questionCount: Int)
    case quizCompleted(correctCount: Int, totalCount: Int, durationSeconds: Int)
    case quizAbandoned(answeredCount: Int, totalCount: Int)
    case levelStart(levelName: String, character: String)
    case levelEnd(levelName: String, isWon: Bool, score: Int)
    case magicUsed(magicType: String)
    case gameAbandoned(levelName: String, questionIndex: Int)
    case virtualCurrencyEarned(currencyName: String, value: Int, source: String)
    case virtualCurrencySpent(itemName: String, currencyName: String, value: Int)
    case achievementUnlocked(achievementID: String)
    case dailySpinClaimed(rewardID: String)
    case weeklyRewardClaimed(dayIndex: Int)
    case adventureRewardClaimed(milestoneID: String, seasonID: String)
    case chestOpened(chestID: String)
    case marketItemPurchased(itemID: String, price: Int)
    case packagePurchased(productID: String)
    case cloudSyncCompleted(result: CloudSyncResult, trigger: CloudSyncTrigger)
    case cloudRestorePromptShown
    case cloudRestorePromptResult(choice: CloudRestoreChoice)
    case notificationPermissionResult(status: AnalyticsPermissionStatus)
    case accountDeleted
    case signOut
}

// MARK: - CONSTANTS

private extension AnalyticsEvent {
    enum Constants {
        // Custom event names — GA4 limits: ≤40 chars, snake_case, no reserved prefixes.
        static let onboardingStepViewed = "onboarding_step_viewed"
        static let attPromptResult = "att_prompt_result"
        static let bookcaseCreated = "bookcase_created"
        static let bookCreated = "book_created"
        static let bookEdited = "book_edited"
        static let bookDeleted = "book_deleted"
        static let packetDownloadStarted = "packet_download_started"
        static let packetDownloadCompleted = "packet_download_completed"
        static let packetDownloadFailed = "packet_download_failed"
        static let dailyWordViewed = "daily_word_viewed"
        static let quizStarted = "quiz_started"
        static let quizCompleted = "quiz_completed"
        static let quizAbandoned = "quiz_abandoned"
        static let magicUsed = "magic_used"
        static let gameAbandoned = "game_abandoned"
        static let dailySpinClaimed = "daily_spin_claimed"
        static let weeklyRewardClaimed = "weekly_reward_claimed"
        static let adventureRewardClaimed = "adventure_reward_claimed"
        static let chestOpened = "chest_opened"
        static let marketItemPurchased = "market_item_purchased"
        static let packagePurchased = "package_purchased"
        static let cloudSyncCompleted = "cloud_sync_completed"
        static let cloudRestorePromptShown = "cloud_restore_prompt_shown"
        static let cloudRestorePromptResult = "cloud_restore_prompt_result"
        static let notificationPermissionResult = "notification_permission_result"
        static let accountDeleted = "account_deleted"
        static let signOut = "sign_out"
        // Custom parameter names.
        static let stepIndex = "step_index"
        static let status = "status"
        static let languagePair = "language_pair"
        static let bookcaseID = "bookcase_id"
        static let hasExample = "has_example"
        static let packetID = "packet_id"
        static let unlockMethod = "unlock_method"
        static let wordCount = "word_count"
        static let reason = "reason"
        static let questionCount = "question_count"
        static let correctCount = "correct_count"
        static let totalCount = "total_count"
        static let durationSeconds = "duration_seconds"
        static let answeredCount = "answered_count"
        static let magicType = "magic_type"
        static let questionIndex = "question_index"
        static let rewardID = "reward_id"
        static let dayIndex = "day_index"
        static let milestoneID = "milestone_id"
        static let seasonID = "season_id"
        static let chestID = "chest_id"
        static let result = "result"
        static let trigger = "trigger"
        static let choice = "choice"
        static let contentTypeBookcase = "bookcase"
    }
}

// MARK: - HELPERS

extension AnalyticsEvent {

    var descriptor: AnalyticsEventDescriptor {
        switch self {
        case .tutorialBegin:
            return AnalyticsEventDescriptor(name: AnalyticsEventTutorialBegin, parameters: [:])
        case let .onboardingStepViewed(stepIndex):
            return AnalyticsEventDescriptor(
                name: Constants.onboardingStepViewed,
                parameters: [Constants.stepIndex: stepIndex]
            )
        case .tutorialComplete:
            return AnalyticsEventDescriptor(name: AnalyticsEventTutorialComplete, parameters: [:])
        case let .login(method):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventLogin,
                parameters: [AnalyticsParameterMethod: method.rawValue]
            )
        case let .signUp(method):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventSignUp,
                parameters: [AnalyticsParameterMethod: method.rawValue]
            )
        case let .attPromptResult(status):
            return AnalyticsEventDescriptor(
                name: Constants.attPromptResult,
                parameters: [Constants.status: status.rawValue]
            )
        case let .bookcaseCreated(languagePair, source):
            return AnalyticsEventDescriptor(
                name: Constants.bookcaseCreated,
                parameters: [Constants.languagePair: languagePair,
                             AnalyticsParameterSource: source.rawValue]
            )
        case let .bookcaseSelected(bookcaseID):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventSelectContent,
                parameters: [AnalyticsParameterContentType: Constants.contentTypeBookcase,
                             AnalyticsParameterItemID: bookcaseID]
            )
        case let .bookCreated(bookcaseID, hasExample):
            return AnalyticsEventDescriptor(
                name: Constants.bookCreated,
                parameters: [Constants.bookcaseID: bookcaseID,
                             Constants.hasExample: hasExample]
            )
        case let .bookEdited(bookcaseID):
            return AnalyticsEventDescriptor(
                name: Constants.bookEdited,
                parameters: [Constants.bookcaseID: bookcaseID]
            )
        case let .bookDeleted(bookcaseID):
            return AnalyticsEventDescriptor(
                name: Constants.bookDeleted,
                parameters: [Constants.bookcaseID: bookcaseID]
            )
        case let .packetDownloadStarted(packetID, unlockMethod):
            return AnalyticsEventDescriptor(
                name: Constants.packetDownloadStarted,
                parameters: [Constants.packetID: packetID,
                             Constants.unlockMethod: unlockMethod.rawValue]
            )
        case let .packetDownloadCompleted(packetID, wordCount):
            return AnalyticsEventDescriptor(
                name: Constants.packetDownloadCompleted,
                parameters: [Constants.packetID: packetID,
                             Constants.wordCount: wordCount]
            )
        case let .packetDownloadFailed(packetID, reason):
            return AnalyticsEventDescriptor(
                name: Constants.packetDownloadFailed,
                parameters: [Constants.packetID: packetID,
                             Constants.reason: reason]
            )
        case .dailyWordViewed:
            return AnalyticsEventDescriptor(name: Constants.dailyWordViewed, parameters: [:])
        case let .quizStarted(bookcaseID, questionCount):
            return AnalyticsEventDescriptor(
                name: Constants.quizStarted,
                parameters: [Constants.bookcaseID: bookcaseID,
                             Constants.questionCount: questionCount]
            )
        case let .quizCompleted(correctCount, totalCount, durationSeconds):
            return AnalyticsEventDescriptor(
                name: Constants.quizCompleted,
                parameters: [Constants.correctCount: correctCount,
                             Constants.totalCount: totalCount,
                             Constants.durationSeconds: durationSeconds]
            )
        case let .quizAbandoned(answeredCount, totalCount):
            return AnalyticsEventDescriptor(
                name: Constants.quizAbandoned,
                parameters: [Constants.answeredCount: answeredCount,
                             Constants.totalCount: totalCount]
            )
        case let .levelStart(levelName, character):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventLevelStart,
                parameters: [AnalyticsParameterLevelName: levelName,
                             AnalyticsParameterCharacter: character]
            )
        case let .levelEnd(levelName, isWon, score):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventLevelEnd,
                parameters: [AnalyticsParameterLevelName: levelName,
                             AnalyticsParameterSuccess: isWon ? 1 : 0,
                             AnalyticsParameterScore: score]
            )
        case let .magicUsed(magicType):
            return AnalyticsEventDescriptor(
                name: Constants.magicUsed,
                parameters: [Constants.magicType: magicType]
            )
        case let .gameAbandoned(levelName, questionIndex):
            return AnalyticsEventDescriptor(
                name: Constants.gameAbandoned,
                parameters: [AnalyticsParameterLevelName: levelName,
                             Constants.questionIndex: questionIndex]
            )
        case let .virtualCurrencyEarned(currencyName, value, source):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventEarnVirtualCurrency,
                parameters: [AnalyticsParameterVirtualCurrencyName: currencyName,
                             AnalyticsParameterValue: value,
                             AnalyticsParameterSource: source]
            )
        case let .virtualCurrencySpent(itemName, currencyName, value):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventSpendVirtualCurrency,
                parameters: [AnalyticsParameterItemName: itemName,
                             AnalyticsParameterVirtualCurrencyName: currencyName,
                             AnalyticsParameterValue: value]
            )
        case let .achievementUnlocked(achievementID):
            return AnalyticsEventDescriptor(
                name: AnalyticsEventUnlockAchievement,
                parameters: [AnalyticsParameterAchievementID: achievementID]
            )
        case let .dailySpinClaimed(rewardID):
            return AnalyticsEventDescriptor(
                name: Constants.dailySpinClaimed,
                parameters: [Constants.rewardID: rewardID]
            )
        case let .weeklyRewardClaimed(dayIndex):
            return AnalyticsEventDescriptor(
                name: Constants.weeklyRewardClaimed,
                parameters: [Constants.dayIndex: dayIndex]
            )
        case let .adventureRewardClaimed(milestoneID, seasonID):
            return AnalyticsEventDescriptor(
                name: Constants.adventureRewardClaimed,
                parameters: [Constants.milestoneID: milestoneID,
                             Constants.seasonID: seasonID]
            )
        case let .chestOpened(chestID):
            return AnalyticsEventDescriptor(
                name: Constants.chestOpened,
                parameters: [Constants.chestID: chestID]
            )
        case let .marketItemPurchased(itemID, price):
            return AnalyticsEventDescriptor(
                name: Constants.marketItemPurchased,
                parameters: [AnalyticsParameterItemID: itemID,
                             AnalyticsParameterPrice: price]
            )
        case let .packagePurchased(productID):
            return AnalyticsEventDescriptor(
                name: Constants.packagePurchased,
                parameters: [AnalyticsParameterItemID: productID]
            )
        case let .cloudSyncCompleted(result, trigger):
            return AnalyticsEventDescriptor(
                name: Constants.cloudSyncCompleted,
                parameters: [Constants.result: result.rawValue,
                             Constants.trigger: trigger.rawValue]
            )
        case .cloudRestorePromptShown:
            return AnalyticsEventDescriptor(name: Constants.cloudRestorePromptShown, parameters: [:])
        case let .cloudRestorePromptResult(choice):
            return AnalyticsEventDescriptor(
                name: Constants.cloudRestorePromptResult,
                parameters: [Constants.choice: choice.rawValue]
            )
        case let .notificationPermissionResult(status):
            return AnalyticsEventDescriptor(
                name: Constants.notificationPermissionResult,
                parameters: [Constants.status: status.rawValue]
            )
        case .accountDeleted:
            return AnalyticsEventDescriptor(name: Constants.accountDeleted, parameters: [:])
        case .signOut:
            return AnalyticsEventDescriptor(name: Constants.signOut, parameters: [:])
        }
    }
}
