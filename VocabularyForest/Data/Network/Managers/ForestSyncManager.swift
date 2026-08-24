//
//  ForestSyncManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.04.2026.
//

import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - PROTOCOL

protocol ForestSyncManagerProtocol: AnyObject {
    var lastSyncDatePublisher: AnyPublisher<Date?, Never> { get }
    func manualSync() async -> Resource<Bool>
    func backgroundSyncIfNeeded()
    func userHaveForest() async -> Resource<SafeForestModel>
    func forceOverwriteCloud() async -> Resource<Bool>
    func downloadAndOverwriteLocal(with safeForest: SafeForestModel) async -> Resource<Bool>
}

// MARK: - MANAGER

final class ForestSyncManager {

    // MARK: - PROPERTIES

    private let db: Firestore
    private let conflictResolver: SyncConflictResolving
    private let cursorStore: ForestSyncCursorStoring
    private let logger: AppLoggerProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let lastSyncSubject = CurrentValueSubject<Date?, Never>(nil)
    /// Server stamp of the forest document from the latest full cloud read; seeds the
    /// pull cursor after a restore so the first delta sync does not re-pull everything.
    private var latestRemoteServerStamp: Date?
    private var isSyncRunning = false

    weak var dataManager: ForestDataManagerProtocol?
    var remoteConfigRepository: RemoteConfigRepositoryProtocol?
    var assetHydrationService: RewardAssetHydrationServiceProtocol?

    // MARK: - INIT

    init(
        db: Firestore,
        conflictResolver: SyncConflictResolving,
        cursorStore: ForestSyncCursorStoring,
        logger: AppLoggerProtocol = AppLogger.shared,
        analyticsService: AnalyticsServiceProtocol = NoopAnalyticsService()
    ) {
        self.db = db
        self.conflictResolver = conflictResolver
        self.cursorStore = cursorStore
        self.logger = logger
        self.analyticsService = analyticsService
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension ForestSyncManager: ForestSyncManagerProtocol {

    var lastSyncDatePublisher: AnyPublisher<Date?, Never> {
        lastSyncSubject.eraseToAnyPublisher()
    }

    func userHaveForest() async -> Resource<SafeForestModel> {
        guard let forestDoc = forestDocument else {
            return .error(error: ForestSyncError.unauthenticated)
        }

        do {
            let docSnapshot = try await forestDoc.getDocument()
            guard docSnapshot.exists, let forestData = docSnapshot.data() else {
                return .error(error: ForestSyncError.noDataToSync)
            }
            latestRemoteServerStamp = ForestSyncMapper.serverStamp(forestData)
            let localForest = dataManager?.fetchSafeForest(contextType: .main).data
            let forestId: UUID
            if let idString = forestData[ForestSyncConstants.idField] as? String,
               let parsedId = UUID(uuidString: idString) {
                forestId = parsedId
            } else if let localForestId = localForest?.forestId {
                // Backward compatibility: older cloud records may not contain "id".
                forestId = localForestId
            } else {
                forestId = UUID()
            }

            let parsedOwnerId = forestData[ForestSyncConstants.ownerId] as? String
            let metadata = ForestSyncMapper.parseMetadata(forestData)
            let lastUpdatedDate = metadata?.lastUpdatedDate ?? Date()
            let belongsToForest = forestMembershipFilter(forestData: forestData, forestId: forestId)
            let catalogResolver = await fetchRewardCatalogResolver()

            async let treesSnapshot = forestDoc.collection(ForestSyncConstants.treesCollection).getDocuments()
            async let animalsSnapshot = forestDoc.collection(ForestSyncConstants.animalsCollection).getDocuments()
            async let sculpturesSnapshot = forestDoc.collection(ForestSyncConstants.sculpturesCollection).getDocuments()
            async let questsSnapshot = forestDoc.collection(ForestSyncConstants.questsCollection).getDocuments()
            async let playerSnapshot = forestDoc.collection(ForestSyncConstants.playerCollection).getDocuments()
            async let dailySnapshot = forestDoc
                .collection(ForestSyncConstants.dailyRewardsCollection)
                .document(ForestSyncConstants.metadataDocument)
                .getDocument()

            let (treesDocs, animalsDocs, sculpturesDocs, questsDocs, playerDocs, dailyDocs) = try await (treesSnapshot, animalsSnapshot, sculpturesSnapshot, questsSnapshot, playerSnapshot, dailySnapshot)

            let parsedTrees = treesDocs.documents.compactMap { document -> TreeModel? in
                let data = document.data()
                guard belongsToForest(data) else { return nil }
                return ForestSyncMapper.parseTree(data, catalogResolver: catalogResolver)
            }

            let parsedAnimals = animalsDocs.documents.compactMap { document -> AnimalModel? in
                let data = document.data()
                guard belongsToForest(data) else { return nil }
                return ForestSyncMapper.parseAnimal(data, catalogResolver: catalogResolver)
            }

            let parsedSculptures = sculpturesDocs.documents.compactMap { document -> SculptureModel? in
                let data = document.data()
                guard belongsToForest(data) else { return nil }
                return ForestSyncMapper.parseSculpture(data, catalogResolver: catalogResolver)
            }

            let parsedQuests = questsDocs.documents.compactMap { document -> QuestTrackModel? in
                let data = document.data()
                guard belongsToForest(data) else { return nil }
                return ForestSyncMapper.parseQuest(data)
            }

            let parsedPlayer = playerDocs.documents.first.map { ForestSyncMapper.parsePlayer($0.data()) }
                ?? PlayerHelper.createDefaultPlayer()
            let parsedDaily = ForestSyncMapper.parseDailyActivities(dailyDocs.data() ?? [:])

            let safeModel = SafeForestModel(
                forestId: forestId,
                ownerId: parsedOwnerId,
                rainValue: metadata?.rainValue ?? 0,
                moneyValue: metadata?.moneyValue ?? 0,
                diamondValue: metadata?.diamondValue ?? 0,
                landHealthPercent: metadata?.landHealthPercent ?? 100,
                pityNatureOpenCount: metadata?.pityNatureOpenCount ?? 0,
                pityAntiqueOpenCount: metadata?.pityAntiqueOpenCount ?? 0,
                pityGeneralOpenCount: metadata?.pityGeneralOpenCount ?? 0,
                landStatus: localForest?.landStatus ?? true,
                isRaining: localForest?.isRaining ?? false,
                lastRainUpdateDate: localForest?.lastRainUpdateDate,
                lastDailyResetDate: localForest?.lastDailyResetDate,
                lastWeeklyResetDate: localForest?.lastWeeklyResetDate,
                lastMonthlyResetDate: localForest?.lastMonthlyResetDate,
                quests: parsedQuests,
                sculptures: parsedSculptures,
                trees: parsedTrees,
                animals: parsedAnimals,
                player: parsedPlayer,
                lastUpdatedDate: lastUpdatedDate,
                lastSyncCloudTime: Date(),
                dailyActivities: parsedDaily
            )

            return .success(safeModel)

        } catch {
            return .error(error: ForestSyncError.firestoreError(error))
        }
    }

    func downloadAndOverwriteLocal(with safeForest: SafeForestModel) async -> Resource<Bool> {
        guard let dataManager else { return .error(error: ForestSyncError.dataManager) }
        guard let currentUID = Auth.auth().currentUser?.uid else {
            return .error(error: ForestSyncError.unauthenticated)
        }

        let result = dataManager.overwriteLocalForest(with: safeForest, ownerId: currentUID, contextType: .main)
        if case .success = result.status {
            // The restored snapshot is as fresh as the last cloud read; nil clears the
            // cursor so legacy data without server stamps still gets one full pull.
            cursorStore.pullCursor = latestRemoteServerStamp
            lastSyncSubject.send(Date())
            // The restore completes with the CoreData write; asset downloads continue in the background.
            // Assets that fail stay at assetReady = false and are retried on the next hydration pass.
            Task { [weak self] in
                await self?.assetHydrationService?.hydrateMissingAssets(for: safeForest)
            }
        }
        return result
    }

    func forceOverwriteCloud() async -> Resource<Bool> {
        guard let dataManager else { return .error(error: ForestSyncError.dataManager) }
        guard let currentUID = Auth.auth().currentUser?.uid else {
            return .error(error: ForestSyncError.unauthenticated)
        }

        let updateIDResult = dataManager.bindForestToUser(uid: currentUID, contextType: .main)

        if case .error = updateIDResult.status {
            return .error(error: nil)
        }

        // Explicit user choice: allowed to replace the cloud forest identity and
        // exempt from the sync cooldown so conflict resolution is never blocked.
        // fullResync uploads every local entity with the forestId tag (writes only,
        // no reads/deletes) so stale cloud documents get filtered out on restore.
        do {
            try await performDeltaSync(allowIdentityOverwrite: true, fullResync: true)
            return .success(true)
        } catch {
            return .error(error: error)
        }
    }

    func manualSync() async -> Resource<Bool> {
        do {
            try checkCooldown(hoursRequired: ForestSyncConstants.manualSyncCooldownHours)
            try await performDeltaSync()
            analyticsService.log(.cloudSyncCompleted(result: .success, trigger: .manual))
            return .success(true)
        } catch {
            let syncResult: CloudSyncResult = switch error as? ForestSyncError {
            case .ownershipMismatch, .cloudForestMismatch: .conflict
            default: .failed
            }
            analyticsService.log(.cloudSyncCompleted(result: syncResult, trigger: .manual))
            return .error(error: error)
        }
    }

    func backgroundSyncIfNeeded() {
        // Called on both cold start and every return to the foreground; the flag keeps
        // overlapping triggers from running two delta syncs against the same batch.
        guard !isSyncRunning else { return }
        isSyncRunning = true
        Task.detached { [weak self] in
            guard let self else { return }
            defer { isSyncRunning = false }
            do {
                try await checkCooldown(hoursRequired: ForestSyncConstants.backgroundSyncCooldownHours)
                try await performDeltaSync()
                analyticsService.log(.cloudSyncCompleted(result: .success, trigger: .auto))
            } catch {
                // Cooldown skips are routine, not failures — logging them would drown the report.
                if let syncError = error as? ForestSyncError, case .cooldownActive = syncError { return }
                if let syncError = error as? ForestSyncError, case .noDataToSync = syncError { return }
                analyticsService.log(.cloudSyncCompleted(result: .failed, trigger: .auto))
                logger.error("Background delta sync failed: \(error.localizedDescription)", category: .sync)
            }
        }
    }
}

// MARK: - PRIVATE HELPERS

private extension ForestSyncManager {

    /// Remote documents that changed after this device's pull cursor.
    struct RemotePullResult {
        var metadata: ForestMetadataUpdate?
        var trees: [TreeModel] = []
        var animals: [AnimalModel] = []
        var sculptures: [SculptureModel] = []
        var quests: [QuestTrackModel] = []
        var player: PlayerModel?
        var dailyActivities: DailyActivitiesModel?
        var maxServerStamp: Date?
    }

    var forestDocument: DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db
            .collection(ForestSyncConstants.usersCollection)
            .document(uid)
            .collection(ForestSyncConstants.forestsCollection)
            .document(ForestSyncConstants.mainForestDocument)
    }

    /// Fetches the rewards catalog from Remote Config. On failure, returns an empty
    /// resolver so the restore still proceeds (assets then default to app bundle).
    func fetchRewardCatalogResolver() async -> RewardCatalogResolver {
        guard let remoteConfigRepository else {
            return RewardCatalogResolver(items: [])
        }
        do {
            let response = try await remoteConfigRepository.fetchRewardsCatalog()
            return RewardCatalogResolver(items: response.model.items ?? [])
        } catch {
            return RewardCatalogResolver(items: [])
        }
    }

    /// Stale-document filtering with no extra read/write cost: the entitiesTagged flag
    /// means every entity was uploaded with a forestId tag. When it is set, documents
    /// tagged for another forest (leftovers from older installs) are ignored.
    func forestMembershipFilter(forestData: [String: Any], forestId: UUID) -> ([String: Any]) -> Bool {
        let entitiesTagged = forestData[ForestSyncConstants.entitiesTaggedField] as? Bool ?? false
        return { data in
            guard entitiesTagged else { return true }
            return data[ForestSyncConstants.forestIdField] as? String == forestId.uuidString
        }
    }

    func checkCooldown(hoursRequired: Double) throws {
        guard Auth.auth().currentUser != nil else {
            throw ForestSyncError.unauthenticated
        }

        // Use the persisted sync time from Core Data so the cooldown survives app
        // restarts; the in-memory subject only covers syncs from the current session.
        let persistedLastSync = dataManager?.fetchSafeForest(contextType: .main).data?.lastSyncCloudTime
        let lastSync = [persistedLastSync, lastSyncSubject.value].compactMap { $0 }.max()

        if let lastSync {
            let timePassed = Date().timeIntervalSince(lastSync)
            let timeRequired = hoursRequired * 3600

            if timePassed < timeRequired {
                let minutesLeft = Int((timeRequired - timePassed) / 60)
                throw ForestSyncError.cooldownActive(waitMinutes: max(1, minutesLeft))
            }
        }
    }

    /// Whether the cloud may hold changes this device has not seen. The check rides on
    /// the forest document read the sync already makes, so a quiet cloud costs no
    /// extra Firestore reads.
    /// - No cursor: first delta sync on this install — pull everything once, which also
    ///   backfills documents written by app versions that predate updatedAtServer.
    /// - No remote stamp: legacy cloud data; the bootstrap write below adds the stamp,
    ///   and a stamp-less query would match nothing anyway.
    func shouldPull(remoteStamp: Date?, cursor: Date?) -> Bool {
        guard let cursor else { return true }
        guard let remoteStamp else { return false }
        return remoteStamp > cursor
    }

    /// Single-document reads (player, daily activities) cannot use the updatedAtServer
    /// query filter, so the same cursor condition is applied after the read.
    func isChanged(_ data: [String: Any], since cursor: Date?) -> Bool {
        guard let cursor else { return true }
        guard let stamp = ForestSyncMapper.serverStamp(data) else { return false }
        return stamp > cursor
    }

    func fetchRemoteChanges(
        forestDoc: DocumentReference,
        forestData: [String: Any],
        forestId: UUID,
        since cursor: Date?
    ) async throws -> RemotePullResult {
        var result = RemotePullResult()
        result.metadata = ForestSyncMapper.parseMetadata(forestData)
        result.maxServerStamp = ForestSyncMapper.serverStamp(forestData)

        let belongsToForest = forestMembershipFilter(forestData: forestData, forestId: forestId)

        func changedDocuments(in collection: String) async throws -> [QueryDocumentSnapshot] {
            let ref = forestDoc.collection(collection)
            guard let cursor else { return try await ref.getDocuments().documents }
            return try await ref
                .whereField(ForestSyncConstants.updatedAtServerField, isGreaterThan: Timestamp(date: cursor))
                .getDocuments()
                .documents
        }

        async let treeDocs = changedDocuments(in: ForestSyncConstants.treesCollection)
        async let animalDocs = changedDocuments(in: ForestSyncConstants.animalsCollection)
        async let sculptureDocs = changedDocuments(in: ForestSyncConstants.sculpturesCollection)
        async let questDocs = changedDocuments(in: ForestSyncConstants.questsCollection)
        async let playerSnapshot = forestDoc
            .collection(ForestSyncConstants.playerCollection)
            .document(ForestSyncConstants.playerDocument)
            .getDocument()
        async let dailySnapshot = forestDoc
            .collection(ForestSyncConstants.dailyRewardsCollection)
            .document(ForestSyncConstants.metadataDocument)
            .getDocument()

        let (trees, animals, sculptures, quests, playerDoc, dailyDoc) = try await (treeDocs, animalDocs, sculptureDocs, questDocs, playerSnapshot, dailySnapshot)

        // The catalog fetch hits Remote Config, so it only runs when an asset-carrying
        // entity actually needs resolving.
        let needsCatalog = !(trees.isEmpty && animals.isEmpty && sculptures.isEmpty)
        let catalogResolver = needsCatalog ? await fetchRewardCatalogResolver() : RewardCatalogResolver(items: [])

        func track(_ data: [String: Any]) {
            if let stamp = ForestSyncMapper.serverStamp(data) {
                result.maxServerStamp = max(result.maxServerStamp ?? stamp, stamp)
            }
        }

        result.trees = trees.compactMap { document -> TreeModel? in
            let data = document.data()
            guard belongsToForest(data) else { return nil }
            track(data)
            return ForestSyncMapper.parseTree(data, catalogResolver: catalogResolver)
        }

        result.animals = animals.compactMap { document -> AnimalModel? in
            let data = document.data()
            guard belongsToForest(data) else { return nil }
            track(data)
            return ForestSyncMapper.parseAnimal(data, catalogResolver: catalogResolver)
        }

        result.sculptures = sculptures.compactMap { document -> SculptureModel? in
            let data = document.data()
            guard belongsToForest(data) else { return nil }
            track(data)
            return ForestSyncMapper.parseSculpture(data, catalogResolver: catalogResolver)
        }

        result.quests = quests.compactMap { document -> QuestTrackModel? in
            let data = document.data()
            guard belongsToForest(data) else { return nil }
            track(data)
            return ForestSyncMapper.parseQuest(data)
        }

        if let playerData = playerDoc.data(), isChanged(playerData, since: cursor) {
            track(playerData)
            result.player = ForestSyncMapper.parsePlayer(playerData)
        }

        if let dailyData = dailyDoc.data(), isChanged(dailyData, since: cursor) {
            track(dailyData)
            result.dailyActivities = ForestSyncMapper.parseDailyActivities(dailyData)
        }

        return result
    }

    func mergeKeyedEntities<Model: SyncTimestamped, Key: Hashable>(
        local: [Model],
        remote: [Model],
        key: (Model) -> Key,
        lastSyncDate: Date
    ) -> (applyRemote: [Model], pushLocal: [Model]) {
        let localByKey = Dictionary(local.map { (key($0), $0) }, uniquingKeysWith: { first, _ in first })
        let remoteByKey = Dictionary(remote.map { (key($0), $0) }, uniquingKeysWith: { first, _ in first })

        var applyRemote: [Model] = []
        var pushLocal: [Model] = []

        for entityKey in Set(localByKey.keys).union(remoteByKey.keys) {
            let resolution = conflictResolver.resolve(
                local: localByKey[entityKey],
                remote: remoteByKey[entityKey],
                lastSyncDate: lastSyncDate
            )
            switch resolution {
            case .applyRemote(let model): applyRemote.append(model)
            case .pushLocal(let model): pushLocal.append(model)
            case .skip: break
            }
        }
        return (applyRemote, pushLocal)
    }

    func performDeltaSync(allowIdentityOverwrite: Bool = false, fullResync: Bool = false) async throws {
        guard let forestDoc = forestDocument, let currentUID = Auth.auth().currentUser?.uid else {
            throw ForestSyncError.unauthenticated
        }
        guard let dataManager else { throw ForestSyncError.dataManager }

        // Captured before reading local state so edits made while the sync is in
        // flight stay newer than the stored sync time and ride the next delta.
        let syncStartDate = Date()

        let forestRes = dataManager.fetchSafeForest(contextType: .main)
        guard forestRes.status == .success, let forest = forestRes.data else {
            throw ForestSyncError.fetchError
        }

        let remoteSnapshot = try await forestDoc.getDocument()
        let remoteData = remoteSnapshot.data()
        let expectedOwnerId = forest.ownerId ?? currentUID
        let remoteId = remoteData?[ForestSyncConstants.idField] as? String
        let remoteOwnerId = remoteData?[ForestSyncConstants.ownerId] as? String

        // Safety guard: never silently overwrite a different forest living in the cloud.
        // This happens e.g. after a reinstall where auth persisted but a brand-new local
        // forest was created. Identity can only change through an explicit user choice
        // (forceOverwriteCloud), which passes allowIdentityOverwrite = true.
        if remoteData != nil {
            if let remoteOwnerId, remoteOwnerId != currentUID {
                throw ForestSyncError.ownershipMismatch
            }
            if let remoteId, remoteId != forest.forestId.uuidString, !allowIdentityOverwrite {
                throw ForestSyncError.cloudForestMismatch
            }
        }

        // On the first sync (no lastSync) or on an explicit user request (fullResync) every entity
        // is uploaded; since all of them then carry a forestId tag, the entitiesTagged flag can be
        // written on the forest document. That flag lets restore discard untagged documents and
        // documents belonging to another forest at no extra cost.
        let isFullUpload = forest.lastSyncCloudTime == nil || fullResync
        let lastSyncDate = isFullUpload ? Date.distantPast : (forest.lastSyncCloudTime ?? Date.distantPast)
        let forestIdString = forest.forestId.uuidString

        // PULL — skipped for forceOverwriteCloud, where local must win wholesale.
        let remoteStamp = remoteData.flatMap { ForestSyncMapper.serverStamp($0) }
        let cursor = cursorStore.pullCursor
        var pull = RemotePullResult()
        var didPull = false
        if !fullResync, let remoteData, shouldPull(remoteStamp: remoteStamp, cursor: cursor) {
            pull = try await fetchRemoteChanges(
                forestDoc: forestDoc,
                forestData: remoteData,
                forestId: forest.forestId,
                since: cursor
            )
            didPull = true
        }

        // MERGE — entity-level last-write-wins between the local forest and the pulled set.
        let (applyTrees, pushTrees) = mergeKeyedEntities(local: forest.trees, remote: pull.trees, key: { $0.id }, lastSyncDate: lastSyncDate)
        let (applyAnimals, pushAnimals) = mergeKeyedEntities(local: forest.animals, remote: pull.animals, key: { $0.id }, lastSyncDate: lastSyncDate)
        let (applySculptures, pushSculptures) = mergeKeyedEntities(local: forest.sculptures, remote: pull.sculptures, key: { $0.id }, lastSyncDate: lastSyncDate)
        let (applyQuests, pushQuests) = mergeKeyedEntities(local: forest.quests, remote: pull.quests, key: { $0.id }, lastSyncDate: lastSyncDate)

        let localMetadata = ForestMetadataUpdate(
            moneyValue: forest.moneyValue,
            diamondValue: forest.diamondValue,
            rainValue: forest.rainValue,
            landHealthPercent: forest.landHealthPercent,
            pityNatureOpenCount: forest.pityNatureOpenCount,
            pityAntiqueOpenCount: forest.pityAntiqueOpenCount,
            pityGeneralOpenCount: forest.pityGeneralOpenCount,
            lastUpdatedDate: forest.lastUpdatedDate
        )
        let metadataResolution = conflictResolver.resolve(local: localMetadata, remote: pull.metadata, lastSyncDate: lastSyncDate)
        let playerResolution = conflictResolver.resolve(local: forest.player, remote: pull.player, lastSyncDate: lastSyncDate)
        let dailyResolution = conflictResolver.resolve(local: forest.dailyActivities, remote: pull.dailyActivities, lastSyncDate: lastSyncDate)

        var remoteChanges = RemoteForestChanges()
        remoteChanges.trees = applyTrees
        remoteChanges.animals = applyAnimals
        remoteChanges.sculptures = applySculptures
        remoteChanges.quests = applyQuests
        if case .applyRemote(let metadata) = metadataResolution { remoteChanges.metadata = metadata }
        if case .applyRemote(let player) = playerResolution { remoteChanges.player = player }
        if case .applyRemote(let daily) = dailyResolution { remoteChanges.dailyActivities = daily }

        if !remoteChanges.isEmpty {
            let applyResult = dataManager.applyRemoteForestChanges(remoteChanges, contextType: .main)
            guard applyResult.status == .success else {
                throw applyResult.error ?? ForestSyncError.fetchError
            }
            // Entities created on another device may reference assets missing on this one.
            if let refreshedForest = dataManager.fetchSafeForest(contextType: .main).data {
                Task { [weak self] in
                    await self?.assetHydrationService?.hydrateMissingAssets(for: refreshedForest)
                }
            }
        }

        // PUSH — only the local winners go up, so a stale device can never overwrite
        // a newer edit that another device already uploaded.
        let batch = db.batch()
        var totalOperations = 0

        if remoteId != forestIdString || remoteOwnerId != expectedOwnerId || isFullUpload {
            var identityData: [String: Any] = [
                ForestSyncConstants.idField: forestIdString,
                ForestSyncConstants.ownerId: expectedOwnerId
            ]
            if isFullUpload {
                identityData[ForestSyncConstants.entitiesTaggedField] = true
            }
            batch.setData(identityData, forDocument: forestDoc, merge: true)
            totalOperations += 1
        }

        if case .pushLocal(let metadata) = metadataResolution {
            batch.setData(ForestSyncMapper.metadataPayload(metadata), forDocument: forestDoc, merge: true)
            totalOperations += 1
        }

        for tree in pushTrees {
            let docRef = forestDoc.collection(ForestSyncConstants.treesCollection).document(tree.id.uuidString)
            batch.setData(ForestSyncMapper.treePayload(tree, forestId: forestIdString), forDocument: docRef, merge: true)
            totalOperations += 1
        }

        for animal in pushAnimals {
            let docRef = forestDoc.collection(ForestSyncConstants.animalsCollection).document(animal.id.uuidString)
            batch.setData(ForestSyncMapper.animalPayload(animal, forestId: forestIdString), forDocument: docRef, merge: true)
            totalOperations += 1
        }

        for sculpture in pushSculptures {
            let docRef = forestDoc.collection(ForestSyncConstants.sculpturesCollection).document(sculpture.id.uuidString)
            batch.setData(ForestSyncMapper.sculpturePayload(sculpture, forestId: forestIdString), forDocument: docRef, merge: true)
            totalOperations += 1
        }

        for quest in pushQuests {
            let docRef = forestDoc.collection(ForestSyncConstants.questsCollection).document(quest.id)
            batch.setData(ForestSyncMapper.questPayload(quest, forestId: forestIdString), forDocument: docRef, merge: true)
            totalOperations += 1
        }

        if case .pushLocal(let player) = playerResolution {
            let playerDocRef = forestDoc.collection(ForestSyncConstants.playerCollection).document(ForestSyncConstants.playerDocument)
            batch.setData(ForestSyncMapper.playerPayload(player), forDocument: playerDocRef, merge: true)
            totalOperations += 1
        }

        if case .pushLocal(let daily) = dailyResolution {
            let dailyDocRef = forestDoc
                .collection(ForestSyncConstants.dailyRewardsCollection)
                .document(ForestSyncConstants.metadataDocument)
            batch.setData(ForestSyncMapper.dailyActivitiesPayload(daily), forDocument: dailyDocRef, merge: true)
            totalOperations += 1
        }

        // A cloud forest written before updatedAtServer existed must get its first
        // stamp even when nothing else changed, otherwise the pull guard could never
        // observe later commits.
        let needsBootstrapStamp = remoteData != nil && remoteStamp == nil
        let hasAppliedRemote = !remoteChanges.isEmpty

        guard totalOperations > 0 || needsBootstrapStamp || didPull || hasAppliedRemote else {
            throw ForestSyncError.noDataToSync
        }

        do {
            if totalOperations > 0 || needsBootstrapStamp {
                // Every commit stamps the forest document with the server time; other
                // devices compare this single field against their cursor to decide
                // whether a pull is needed at all.
                batch.setData([ForestSyncConstants.updatedAtServerField: FieldValue.serverTimestamp()], forDocument: forestDoc, merge: true)
                try await batch.commit()
                // One extra read per pushing sync: the committed server time becomes the
                // cursor, so the next pull skips this device's own writes. Best effort —
                // on failure the stale cursor only causes one redundant pull, never data loss.
                let committedData = (try? await forestDoc.getDocument())?.data()
                cursorStore.pullCursor = committedData.flatMap { ForestSyncMapper.serverStamp($0) } ?? pull.maxServerStamp ?? cursor
            } else if let maxStamp = pull.maxServerStamp {
                cursorStore.pullCursor = maxStamp
            }
        } catch {
            throw ForestSyncError.firestoreError(error)
        }

        _ = dataManager.updateLastSyncCloudTime(date: syncStartDate, contextType: .main)
        lastSyncSubject.send(syncStartDate)
    }
}
