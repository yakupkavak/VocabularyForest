//
//  ForestSyncMapper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.08.2026.
//

import FirebaseFirestore

/// Maps forest models to Firestore payloads and back. Every payload carries
/// updatedAtServer so the pull side can query only the documents that changed
/// after this device's cursor.
enum ForestSyncMapper {}

// MARK: - PAYLOADS

extension ForestSyncMapper {

    static func treePayload(_ tree: TreeModel, forestId: String) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.idField: tree.id.uuidString,
            ForestSyncConstants.forestIdField: forestId,
            ForestSyncConstants.typeField: ForestSyncConstants.plantType,
            ForestSyncConstants.assetNameField: tree.assetName,
            ForestSyncConstants.characterNameField: tree.characterName,
            ForestSyncConstants.xPositionField: tree.xPosition,
            ForestSyncConstants.yPositionField: tree.yPosition,
            ForestSyncConstants.isAliveField: tree.isAlive,
            ForestSyncConstants.healthValueField: tree.treeHealthValue,
            ForestSyncConstants.createdDateField: tree.createdDate,
            ForestSyncConstants.lastUpdatedDateField: tree.lastUpdatedDate,
            ForestSyncConstants.updatedAtServerField: FieldValue.serverTimestamp()
        ]
        if let rewardId = tree.rewardId {
            payload[ForestSyncConstants.rewardIdField] = rewardId
        }
        return payload
    }

    static func animalPayload(_ animal: AnimalModel, forestId: String) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.idField: animal.id.uuidString,
            ForestSyncConstants.forestIdField: forestId,
            ForestSyncConstants.typeField: ForestSyncConstants.animalType,
            ForestSyncConstants.assetNameField: animal.assetName,
            ForestSyncConstants.characterNameField: animal.characterName,
            ForestSyncConstants.xPositionField: animal.xPosition,
            ForestSyncConstants.yPositionField: animal.yPosition,
            ForestSyncConstants.isAliveField: animal.isAlive,
            ForestSyncConstants.healthValueField: animal.healthValue,
            ForestSyncConstants.createdDateField: animal.createdDate,
            ForestSyncConstants.lastUpdatedDateField: animal.lastUpdatedDate,
            ForestSyncConstants.updatedAtServerField: FieldValue.serverTimestamp()
        ]
        if let rewardId = animal.rewardId {
            payload[ForestSyncConstants.rewardIdField] = rewardId
        }
        return payload
    }

    static func sculpturePayload(_ sculpture: SculptureModel, forestId: String) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.idField: sculpture.id.uuidString,
            ForestSyncConstants.forestIdField: forestId,
            ForestSyncConstants.typeField: ForestSyncConstants.sculptureType,
            ForestSyncConstants.assetNameField: sculpture.assetName,
            ForestSyncConstants.characterNameField: sculpture.characterName,
            ForestSyncConstants.xPositionField: sculpture.xPosition,
            ForestSyncConstants.yPositionField: sculpture.yPosition,
            ForestSyncConstants.createdDateField: sculpture.createdDate,
            ForestSyncConstants.lastUpdatedDateField: sculpture.lastUpdatedDate,
            ForestSyncConstants.updatedAtServerField: FieldValue.serverTimestamp()
        ]
        if let rewardId = sculpture.rewardId {
            payload[ForestSyncConstants.rewardIdField] = rewardId
        }
        return payload
    }

    static func questPayload(_ quest: QuestTrackModel, forestId: String) -> [String: Any] {
        [
            ForestSyncConstants.idField: quest.id,
            ForestSyncConstants.forestIdField: forestId,
            ForestSyncConstants.statusField: quest.status.valueForCoreData,
            ForestSyncConstants.currentProgressCountField: quest.currentProgressCount,
            ForestSyncConstants.lastUpdatedDateField: quest.lastUpdatedDate,
            ForestSyncConstants.updatedAtServerField: FieldValue.serverTimestamp()
        ]
    }

    static func playerPayload(_ player: PlayerModel) -> [String: Any] {
        [
            ForestSyncConstants.nameField: player.name,
            ForestSyncConstants.lastUpdatedDateField: player.lastUpdateDate,
            ForestSyncConstants.updatedAtServerField: FieldValue.serverTimestamp()
        ]
    }

    static func metadataPayload(_ metadata: ForestMetadataUpdate) -> [String: Any] {
        [
            ForestSyncConstants.moneyValueField: metadata.moneyValue,
            ForestSyncConstants.diamondValueField: metadata.diamondValue,
            ForestSyncConstants.rainValueField: metadata.rainValue,
            ForestSyncConstants.landHealthPercentField: metadata.landHealthPercent,
            ForestSyncConstants.pityNatureOpenCountField: metadata.pityNatureOpenCount,
            ForestSyncConstants.pityAntiqueOpenCountField: metadata.pityAntiqueOpenCount,
            ForestSyncConstants.pityGeneralOpenCountField: metadata.pityGeneralOpenCount,
            ForestSyncConstants.lastUpdatedDateField: metadata.lastUpdatedDate
        ]
    }

    static func dailyActivitiesPayload(_ daily: DailyActivitiesModel) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.weeklyStreakCurrentDayField: daily.weeklyStreakCurrentDay,
            ForestSyncConstants.monthlyLongLearnedCountField: daily.monthlyLongLearnedCount,
            ForestSyncConstants.monthlyShortLearnedCountField: daily.monthlyShortLearnedCount,
            ForestSyncConstants.fixedTimeZoneField: daily.fixedTimeZone ?? TimeZone.current.identifier,
            ForestSyncConstants.lastUpdatedDateField: daily.lastUpdatedDate,
            ForestSyncConstants.dailyKillGoldCountField: daily.dailyKillGoldCount,
            ForestSyncConstants.updatedAtServerField: FieldValue.serverTimestamp()
        ]

        if let killGoldResetDate = daily.killGoldLastResetDate {
            payload[ForestSyncConstants.killGoldLastResetDateField] = killGoldResetDate
        }
        if let claimDate = daily.weeklyStreakLastClaimDate {
            payload[ForestSyncConstants.weeklyStreakLastClaimDateField] = claimDate
        }
        if let fetchDate = daily.lastFetchDate {
            payload[ForestSyncConstants.lastFetchDateField] = fetchDate
        }
        if let spinDate = daily.dailySpinLastUsedDate {
            payload[ForestSyncConstants.dailySpinLastUsedDateField] = spinDate
        }
        if let seasonID = daily.adventureSeasonID {
            payload[ForestSyncConstants.adventureSeasonIDField] = seasonID
        }
        if let claimedLong = daily.claimedLongTiers {
            payload[ForestSyncConstants.claimedLongTiersField] = claimedLong
        }
        if let claimedShort = daily.claimedShortTiers {
            payload[ForestSyncConstants.claimedShortTiersField] = claimedShort
        }

        return payload
    }
}

// MARK: - PARSERS

extension ForestSyncMapper {

    /// Server timestamp of the document's last commit; nil on documents written
    /// by app versions that predate the two-way sync.
    static func serverStamp(_ data: [String: Any]) -> Date? {
        (data[ForestSyncConstants.updatedAtServerField] as? Timestamp)?.dateValue()
    }

    static func parseTree(_ data: [String: Any], catalogResolver: RewardCatalogResolver) -> TreeModel? {
        guard let idString = data[ForestSyncConstants.idField] as? String,
              let id = UUID(uuidString: idString) else { return nil }

        let assetName = data[ForestSyncConstants.assetNameField] as? String ?? ""
        let rewardId = data[ForestSyncConstants.rewardIdField] as? String
        let resolvedAsset = catalogResolver.resolveAsset(rewardId: rewardId, assetName: assetName)

        return TreeModel(
            id: id,
            assetName: assetName,
            createdDate: (data[ForestSyncConstants.createdDateField] as? Timestamp)?.dateValue() ?? Date(),
            characterName: data[ForestSyncConstants.characterNameField] as? String ?? "",
            assetSource: resolvedAsset.assetSource,
            poster: resolvedAsset.poster,
            isAlive: data[ForestSyncConstants.isAliveField] as? Bool ?? true,
            treeHealthValue: data[ForestSyncConstants.healthValueField] as? Int ?? 10,
            xPosition: data[ForestSyncConstants.xPositionField] as? Double ?? 0.0,
            yPosition: data[ForestSyncConstants.yPositionField] as? Double ?? 0.0,
            lastUpdatedDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date(),
            rewardId: rewardId,
            assetReady: resolvedAsset.assetSource == .appAssets
        )
    }

    static func parseAnimal(_ data: [String: Any], catalogResolver: RewardCatalogResolver) -> AnimalModel? {
        guard let idString = data[ForestSyncConstants.idField] as? String,
              let id = UUID(uuidString: idString) else { return nil }

        let assetName = data[ForestSyncConstants.assetNameField] as? String ?? ""
        let rewardId = data[ForestSyncConstants.rewardIdField] as? String
        let resolvedAsset = catalogResolver.resolveAsset(rewardId: rewardId, assetName: assetName)

        return AnimalModel(
            id: id,
            assetName: assetName,
            createdDate: (data[ForestSyncConstants.createdDateField] as? Timestamp)?.dateValue() ?? Date(),
            characterName: data[ForestSyncConstants.characterNameField] as? String ?? "",
            assetSource: resolvedAsset.assetSource,
            poster: resolvedAsset.poster,
            healthValue: data[ForestSyncConstants.healthValueField] as? Int ?? 10,
            isAlive: data[ForestSyncConstants.isAliveField] as? Bool ?? true,
            xPosition: data[ForestSyncConstants.xPositionField] as? Double ?? 0.0,
            yPosition: data[ForestSyncConstants.yPositionField] as? Double ?? 0.0,
            lastUpdatedDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date(),
            rewardId: rewardId,
            assetReady: resolvedAsset.assetSource == .appAssets
        )
    }

    static func parseSculpture(_ data: [String: Any], catalogResolver: RewardCatalogResolver) -> SculptureModel? {
        guard let idString = data[ForestSyncConstants.idField] as? String,
              let id = UUID(uuidString: idString) else { return nil }

        let assetName = data[ForestSyncConstants.assetNameField] as? String ?? ""
        let rewardId = data[ForestSyncConstants.rewardIdField] as? String
        let resolvedAsset = catalogResolver.resolveAsset(rewardId: rewardId, assetName: assetName)

        return SculptureModel(
            id: id,
            assetName: assetName,
            createdDate: (data[ForestSyncConstants.createdDateField] as? Timestamp)?.dateValue() ?? Date(),
            characterName: data[ForestSyncConstants.characterNameField] as? String ?? "",
            assetSource: resolvedAsset.assetSource,
            poster: resolvedAsset.poster,
            xPosition: data[ForestSyncConstants.xPositionField] as? Double ?? 0.0,
            yPosition: data[ForestSyncConstants.yPositionField] as? Double ?? 0.0,
            lastUpdatedDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date(),
            rewardId: rewardId,
            assetReady: resolvedAsset.assetSource == .appAssets
        )
    }

    static func parseQuest(_ data: [String: Any]) -> QuestTrackModel? {
        guard let id = data[ForestSyncConstants.idField] as? String else { return nil }

        return QuestTrackModel(
            id: id,
            lastUpdatedDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date(),
            status: QuestStatus.convertFromCoreData(string: data[ForestSyncConstants.statusField] as? String),
            currentProgressCount: data[ForestSyncConstants.currentProgressCountField] as? Int ?? 0
        )
    }

    static func parsePlayer(_ data: [String: Any]) -> PlayerModel {
        PlayerModel(
            name: data[ForestSyncConstants.nameField] as? String ?? PlayerHelper.createDefaultPlayer().name,
            lastUpdateDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    static func parseMetadata(_ data: [String: Any]) -> ForestMetadataUpdate? {
        guard let lastUpdatedDate = (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() else {
            return nil
        }
        return ForestMetadataUpdate(
            moneyValue: data[ForestSyncConstants.moneyValueField] as? Int ?? 0,
            diamondValue: data[ForestSyncConstants.diamondValueField] as? Int ?? 0,
            rainValue: data[ForestSyncConstants.rainValueField] as? Int ?? 0,
            landHealthPercent: data[ForestSyncConstants.landHealthPercentField] as? Int ?? 100,
            pityNatureOpenCount: data[ForestSyncConstants.pityNatureOpenCountField] as? Int ?? 0,
            pityAntiqueOpenCount: data[ForestSyncConstants.pityAntiqueOpenCountField] as? Int ?? 0,
            pityGeneralOpenCount: data[ForestSyncConstants.pityGeneralOpenCountField] as? Int ?? 0,
            lastUpdatedDate: lastUpdatedDate
        )
    }

    static func parseDailyActivities(_ data: [String: Any]) -> DailyActivitiesModel {
        DailyActivitiesModel(
            adventureSeasonID: data[ForestSyncConstants.adventureSeasonIDField] as? String,
            claimedLongTiers: data[ForestSyncConstants.claimedLongTiersField] as? String,
            claimedShortTiers: data[ForestSyncConstants.claimedShortTiersField] as? String,
            monthlyLongLearnedCount: data[ForestSyncConstants.monthlyLongLearnedCountField] as? Int ?? 0,
            monthlyShortLearnedCount: data[ForestSyncConstants.monthlyShortLearnedCountField] as? Int ?? 0,
            weeklyStreakLastClaimDate: (data[ForestSyncConstants.weeklyStreakLastClaimDateField] as? Timestamp)?.dateValue(),
            weeklyStreakCurrentDay: data[ForestSyncConstants.weeklyStreakCurrentDayField] as? Int ?? 0,
            lastFetchDate: (data[ForestSyncConstants.lastFetchDateField] as? Timestamp)?.dateValue(),
            fixedTimeZone: data[ForestSyncConstants.fixedTimeZoneField] as? String ?? TimeZone.current.identifier,
            dailySpinLastUsedDate: (data[ForestSyncConstants.dailySpinLastUsedDateField] as? Timestamp)?.dateValue(),
            lastUpdatedDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date(),
            dailyKillGoldCount: data[ForestSyncConstants.dailyKillGoldCountField] as? Int ?? 0,
            killGoldLastResetDate: (data[ForestSyncConstants.killGoldLastResetDateField] as? Timestamp)?.dateValue()
        )
    }
}
