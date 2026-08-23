//
//  ForestSyncConstants.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.08.2026.
//

import Foundation

// MARK: - CONSTANTS

enum ForestSyncConstants {
    static let usersCollection = "Users"
    static let forestsCollection = "Forests"
    static let mainForestDocument = "mainForest"
    static let playerDocument = "player"

    static let treesCollection = "Trees"
    static let animalsCollection = "Animals"
    static let sculpturesCollection = "Sculptures"
    static let questsCollection = "Quests"
    static let playerCollection = "Player"
    static let dailyRewardsCollection = "DailyRewards"

    static let idField = "id"
    static let nameField = "name"
    static let typeField = "type"
    static let assetNameField = "assetName"
    static let characterNameField = "characterName"
    static let xPositionField = "xPosition"
    static let yPositionField = "yPosition"
    static let isAliveField = "isAlive"
    static let healthValueField = "healthValue"
    static let createdDateField = "createdDate"
    static let lastUpdatedDateField = "lastUpdatedDate"
    static let rewardIdField = "rewardId"
    /// Tags which forest an entity document belongs to (used to filter out stale documents).
    static let forestIdField = "forestId"
    /// On the forest document: signals that every entity was uploaded with a forestId tag.
    static let entitiesTaggedField = "entitiesTagged"
    /// Firestore server time of the last commit that touched the document. Written with
    /// FieldValue.serverTimestamp() on every push; the pull side compares it against the
    /// device's cursor, so clock skew between devices can never hide an update.
    static let updatedAtServerField = "updatedAtServer"

    static let moneyValueField = "moneyValue"
    static let diamondValueField = "diamondValue"
    static let rainValueField = "rainValue"
    static let landHealthPercentField = "landHealthPercent"

    static let titleField = "title"
    static let descriptionField = "description"
    static let rewardTypeField = "rewardType"
    static let rewardValueField = "rewardValue"
    static let statusField = "status"
    static let targetCountField = "targetCount"
    static let currentProgressCountField = "currentProgressCount"
    static let questionTypeField = "questionType"
    static let battleEnemyModelField = "battleEnemyModel"
    static let gameLevelField = "gameLevel"

    static let metadataDocument = "metadata"
    static let weeklyStreakCurrentDayField = "weeklyStreakCurrentDayField"
    static let weeklyStreakLastClaimDateField = "weeklyStreakLastClaimDate"
    static let lastFetchDateField = "lastFetchDate"
    static let fixedTimeZoneField = "fixedTimeZone"
    static let dailySpinLastUsedDateField = "dailySpinLastUsedDate"
    static let firstVisitTimestamp = "firstVisitTimestamp"
    static let dailyKillGoldCountField = "dailyKillGoldCount"
    static let killGoldLastResetDateField = "killGoldLastResetDate"

    static let adventureSeasonIDField = "adventureSeasonID"
    static let claimedLongTiersField = "claimedLongTiers"
    static let claimedShortTiersField = "claimedShortTiers"
    static let monthlyLongLearnedCountField = "monthlyLongLearnedCount"
    static let monthlyShortLearnedCountField = "monthlyShortLearnedCount"

    static let plantType = "plant"
    static let animalType = "animal"
    static let sculptureType = "sculpture"
    static let ownerId = "ownerId"

    static let manualSyncCooldownHours: Double = 1.0
    static let backgroundSyncCooldownHours: Double = 2.0
}

// MARK: - ERRORS

enum ForestSyncError: LocalizedError {
    case cooldownActive(waitMinutes: Int)
    case unauthenticated
    case noDataToSync
    case firestoreError(Error)
    case fetchError
    case dataManager
    case ownershipMismatch
    case cloudForestMismatch

    var errorDescription: String? {
        switch self {
        case .cooldownActive(let waitMinutes):
            return String(localized: "Lütfen yeni bir yedekleme yapmak için \(waitMinutes) dakika bekleyin.")
        case .unauthenticated:
            return String(localized: "Yedekleme yapmak için giriş yapmalısınız.")
        case .noDataToSync:
            return String(localized: "Senkronize edilecek yeni bir veri bulunamadı.")
        case .firestoreError(let error):
            return error.localizedDescription
        case .fetchError:
            return String(localized: "Yerel veriler okunurken bir hata oluştu.")
        case .dataManager:
            return String(localized: "Forest data manager eklenmedi.")
        case .ownershipMismatch:
            return String(localized: "Bu orman başka bir hesaba bağlı. Lütfen kendi hesabınıza giriş yapın veya oyunu sıfırlayın.")
        case .cloudForestMismatch:
            return String(localized: "Buluttaki orman bu cihazdakinden farklı. Lütfen hangi ormanı kullanmak istediğinizi seçin.")
        }
    }
}
