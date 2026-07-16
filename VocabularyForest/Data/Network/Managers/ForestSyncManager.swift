//
//  ForestSyncManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.04.2026.
//

import Combine
import FirebaseFirestore
import FirebaseAuth

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
    static let backgroundSyncCooldownHours: Double = 24.0
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
        }
    }
}

// MARK: - PROTOCOL

protocol ForestSyncManagerProtocol: AnyObject {
    var lastSyncDatePublisher: AnyPublisher<Date?, Never> { get }
    func manualSync() async -> Resource<Bool>
    func backgroundSyncIfNeeded()
    func userHaveForest() async -> Resource<SafeForestModel>
    func forceOverwriteCloud() async -> Resource<Bool>
    func downloadAndOverwriteLocal(with safeForest: SafeForestModel) async -> Resource<Bool>
    func checkHasConflictOnlyMetadata() async -> Resource<Bool>
    func deleteCloudData() async throws
}

// MARK: - MANAGER

class ForestSyncManager: ForestSyncManagerProtocol {
    
    // MARK: - PRIVATE PROPERTIES
    
    private let db = Firestore.firestore()
    private let lastSyncSubject = CurrentValueSubject<Date?, Never>(nil)
    
    private var forestDocument: DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db
            .collection(ForestSyncConstants.usersCollection)
            .document(uid)
            .collection(ForestSyncConstants.forestsCollection)
            .document(ForestSyncConstants.mainForestDocument)
    }
    
    // MARK: - PROPERTIES
    
    weak var dataManager: ForestDataManagerProtocol?
    var remoteConfigRepository: RemoteConfigRepositoryProtocol?
    var assetHydrationService: RewardAssetHydrationServiceProtocol?
    
    var lastSyncDatePublisher: AnyPublisher<Date?, Never> {
        lastSyncSubject.eraseToAnyPublisher()
    }
    
    // MARK: - INIT
    
    init() { }
    
    // MARK: - PUBLIC METHODS
    
    func checkHasConflictOnlyMetadata() async -> Resource<Bool> {
        guard let forestDoc = forestDocument else {
            return .error(error: ForestSyncError.unauthenticated)
        }
        
        do {
            let docSnapshot = try await forestDoc.getDocument()
            guard docSnapshot.exists, let forestData = docSnapshot.data() else {
                return .success(false)
            }
            
            let cloudUpdatedDate = (forestData[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date()
            
            guard let dataManager = dataManager else { return .error(error: ForestSyncError.dataManager) }
            let localForestRes = dataManager.fetchSafeForest(contextType: .main)
            
            guard localForestRes.status == .success, let localForest = localForestRes.data else {
                return .success(true)
            }

            guard let localSyncTime = localForest.lastSyncCloudTime else {
                return .success(true)
            }

            // Conflict only when the cloud forest changed after this device's last sync,
            // i.e. another device uploaded newer data. Small tolerance absorbs clock skew
            // between Firestore server timestamps and the local sync timestamp.
            let cloudIsNewerBySeconds = cloudUpdatedDate.timeIntervalSince(localSyncTime)
            return .success(cloudIsNewerBySeconds > 2.0)
        } catch {
            return .error(error: ForestSyncError.firestoreError(error))
        }
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
            
            let moneyValue = forestData[ForestSyncConstants.moneyValueField] as? Int ?? 0
            let diamondValue = forestData[ForestSyncConstants.diamondValueField] as? Int ?? 0
            let rainValue = forestData[ForestSyncConstants.rainValueField] as? Int ?? 0
            let landHealthPercent = forestData[ForestSyncConstants.landHealthPercentField] as? Int ?? 100
            
            let lastUpdatedDate = (forestData[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date()
            
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
                    rewardId: rewardId
                )
            }
            
            let parsedAnimals = animalsDocs.documents.compactMap { document -> AnimalModel? in
                let data = document.data()
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
                    rewardId: rewardId
                )
            }
            
            let parsedSculptures = sculpturesDocs.documents.compactMap { document -> SculptureModel? in
                let data = document.data()
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
                    rewardId: rewardId
                )
            }
            
            let parsedQuests = questsDocs.documents.compactMap { document -> QuestTrackModel? in
                let data = document.data()
                guard let id = data[ForestSyncConstants.idField] as? String else { return nil }
                
                return QuestTrackModel(
                    id: id,
                    lastUpdatedDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date(),
                    status: QuestStatus.convertFromCoreData(string: data[ForestSyncConstants.statusField] as? String),
                    currentProgressCount: data[ForestSyncConstants.currentProgressCountField] as? Int ?? 0
                )
            }
            
            let parsedPlayer = playerDocs.documents.compactMap { document -> PlayerModel in
                let data = document.data()
                return PlayerModel(
                    name: data[ForestSyncConstants.nameField] as? String ?? PlayerHelper.createDefaultPlayer().name,
                    lastUpdateDate: (data[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date()
                )
            }.first ?? PlayerHelper.createDefaultPlayer()
            
            let dailyData = dailyDocs.data() ?? [:]
            let parsedDaily = DailyActivitiesModel(
                adventureSeasonID: dailyData[ForestSyncConstants.adventureSeasonIDField] as? String,
                claimedLongTiers: dailyData[ForestSyncConstants.claimedLongTiersField] as? String,
                claimedShortTiers: dailyData[ForestSyncConstants.claimedShortTiersField] as? String,
                monthlyLongLearnedCount: dailyData[ForestSyncConstants.monthlyLongLearnedCountField] as? Int ?? 0,
                monthlyShortLearnedCount: dailyData[ForestSyncConstants.monthlyShortLearnedCountField] as? Int ?? 0,
                weeklyStreakLastClaimDate: (dailyData[ForestSyncConstants.weeklyStreakLastClaimDateField] as? Timestamp)?.dateValue(),
                weeklyStreakCurrentDay: dailyData[ForestSyncConstants.weeklyStreakCurrentDayField] as? Int ?? 0,
                lastFetchDate: (dailyData[ForestSyncConstants.lastFetchDateField] as? Timestamp)?.dateValue(),
                fixedTimeZone: dailyData[ForestSyncConstants.fixedTimeZoneField] as? String ?? TimeZone.current.identifier,
                dailySpinLastUsedDate: (dailyData[ForestSyncConstants.dailySpinLastUsedDateField] as? Timestamp)?.dateValue(),
                lastUpdatedDate: (dailyData[ForestSyncConstants.lastUpdatedDateField] as? Timestamp)?.dateValue() ?? Date(),
                dailyKillGoldCount: dailyData[ForestSyncConstants.dailyKillGoldCountField] as? Int ?? 0,
                killGoldLastResetDate: (dailyData[ForestSyncConstants.killGoldLastResetDateField] as? Timestamp)?.dateValue()
            )
            
            let safeModel = SafeForestModel(
                forestId: forestId,
                ownerId: parsedOwnerId,
                rainValue: rainValue,
                moneyValue: moneyValue,
                diamondValue: diamondValue,
                landHealthPercent: landHealthPercent,
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
            lastSyncSubject.send(Date())
            // Best effort: re-download remote assets that are not on this device yet.
            await assetHydrationService?.hydrateMissingAssets(for: safeForest)
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
        return await manualSync()
    }
    
    func manualSync() async -> Resource<Bool> {
        do {
            try checkCooldown(hoursRequired: ForestSyncConstants.manualSyncCooldownHours)
            try await performDeltaSync()
            return .success(true)
        } catch {
            return .error(error: error)
        }
    }
    
    /// Hesap silme akışı: kullanıcının Firestore'daki tüm verisini siler ve yerel ormanın hesap bağını koparır.
    func deleteCloudData() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw ForestSyncError.unauthenticated }
        
        let userDoc = db.collection(ForestSyncConstants.usersCollection).document(uid)
        let forestDoc = userDoc
            .collection(ForestSyncConstants.forestsCollection)
            .document(ForestSyncConstants.mainForestDocument)
        
        let subcollections = [
            ForestSyncConstants.treesCollection,
            ForestSyncConstants.animalsCollection,
            ForestSyncConstants.sculpturesCollection,
            ForestSyncConstants.questsCollection,
            ForestSyncConstants.playerCollection,
            ForestSyncConstants.dailyRewardsCollection
        ]
        
        do {
            for collectionName in subcollections {
                let documents = try await forestDoc.collection(collectionName).getDocuments().documents
                // Firestore batch limiti 500 yazma olduğu için parçalara bölüyoruz.
                for chunkStart in stride(from: 0, to: documents.count, by: 400) {
                    let batch = db.batch()
                    documents[chunkStart..<min(chunkStart + 400, documents.count)].forEach {
                        batch.deleteDocument($0.reference)
                    }
                    try await batch.commit()
                }
            }
            let finalBatch = db.batch()
            finalBatch.deleteDocument(forestDoc)
            finalBatch.deleteDocument(userDoc)
            try await finalBatch.commit()
        } catch {
            throw ForestSyncError.firestoreError(error)
        }
        
        _ = dataManager?.bindForestToUser(uid: nil, contextType: .main)
    }
    
    func backgroundSyncIfNeeded() {
        Task.detached { [weak self] in
            guard let self else { return }
            do {
                try await checkCooldown(hoursRequired: ForestSyncConstants.backgroundSyncCooldownHours)
                try await performDeltaSync()
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - PRIVATE HELPERS

private extension ForestSyncManager {
    
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
    
    func checkCooldown(hoursRequired: Double) throws {
        guard Auth.auth().currentUser != nil else {
            throw ForestSyncError.unauthenticated
        }
        
        if let lastSync = lastSyncSubject.value {
            let timePassed = Date().timeIntervalSince(lastSync)
            let timeRequired = hoursRequired * 3600
            
            if timePassed < timeRequired {
                let minutesLeft = Int((timeRequired - timePassed) / 60)
                throw ForestSyncError.cooldownActive(waitMinutes: max(1, minutesLeft))
            }
        }
    }
    
    func performDeltaSync() async throws {
        guard let forestDoc = forestDocument else { throw ForestSyncError.unauthenticated }
        guard let currentUID = Auth.auth().currentUser?.uid else { throw ForestSyncError.unauthenticated }
        guard let dataManager else { throw ForestSyncError.fetchError }
        
        let forestRes = dataManager.fetchSafeForest(contextType: .main)
        guard forestRes.status == .success, let forest = forestRes.data else {
            throw ForestSyncError.fetchError
        }
        
        let lastSyncDate = forest.lastSyncCloudTime ?? Date.distantPast
        
        let batch = db.batch()
        var totalOperations = 0
        
        let remoteSnapshot = try await forestDoc.getDocument()
        let remoteData = remoteSnapshot.data()
        let expectedOwnerId = forest.ownerId ?? currentUID
        let remoteId = remoteData?[ForestSyncConstants.idField] as? String
        let remoteOwnerId = remoteData?[ForestSyncConstants.ownerId] as? String
        
        if remoteId != forest.forestId.uuidString || remoteOwnerId != expectedOwnerId {
            let identityData: [String: Any] = [
                ForestSyncConstants.idField: forest.forestId.uuidString,
                ForestSyncConstants.ownerId: expectedOwnerId
            ]
            batch.setData(identityData, forDocument: forestDoc, merge: true)
            totalOperations += 1
        }
        
        if forest.lastUpdatedDate > lastSyncDate {
            let mainData: [String: Any] = [
                ForestSyncConstants.moneyValueField: forest.moneyValue,
                ForestSyncConstants.diamondValueField: forest.diamondValue,
                ForestSyncConstants.rainValueField: forest.rainValue,
                ForestSyncConstants.landHealthPercentField: forest.landHealthPercent,
                ForestSyncConstants.lastUpdatedDateField: forest.lastUpdatedDate
            ]
            batch.setData(mainData, forDocument: forestDoc, merge: true)
            totalOperations += 1
        }
        
        let updatedTrees = forest.trees.filter { $0.lastUpdatedDate > lastSyncDate }
        for tree in updatedTrees {
            let docRef = forestDoc.collection(ForestSyncConstants.treesCollection).document(tree.id.uuidString)
            batch.setData(treePayload(tree), forDocument: docRef, merge: true)
            totalOperations += 1
        }
        
        let updatedAnimals = forest.animals.filter { $0.lastUpdatedDate > lastSyncDate }
        for animal in updatedAnimals {
            let docRef = forestDoc.collection(ForestSyncConstants.animalsCollection).document(animal.id.uuidString)
            batch.setData(animalPayload(animal), forDocument: docRef, merge: true)
            totalOperations += 1
        }
        
        let updatedSculptures = forest.sculptures.filter { $0.lastUpdatedDate > lastSyncDate }
        for sculpture in updatedSculptures {
            let docRef = forestDoc.collection(ForestSyncConstants.sculpturesCollection).document(sculpture.id.uuidString)
            batch.setData(sculpturePayload(sculpture), forDocument: docRef, merge: true)
            totalOperations += 1
        }
        
        let updatedQuests = forest.quests.filter { $0.lastUpdatedDate > lastSyncDate }
        for quest in updatedQuests {
            let docRef = forestDoc.collection(ForestSyncConstants.questsCollection).document(quest.id)
            batch.setData(questPayload(quest), forDocument: docRef, merge: true)
            totalOperations += 1
        }
        
        if forest.player.lastUpdateDate > lastSyncDate {
            let playerDocRef = forestDoc.collection(ForestSyncConstants.playerCollection).document(ForestSyncConstants.playerDocument)
            batch.setData(playerPayload(forest.player), forDocument: playerDocRef, merge: true)
            totalOperations += 1
        }
        
        if forest.dailyActivities.lastUpdatedDate > lastSyncDate {
            let dailyDocRef = forestDoc
                .collection(ForestSyncConstants.dailyRewardsCollection)
                .document(ForestSyncConstants.metadataDocument)
            batch.setData(
                dailyActivitiesPayload(forest.dailyActivities),
                forDocument: dailyDocRef,
                merge: true
            )
            totalOperations += 1
        }
        
        guard totalOperations > 0 else {
            throw ForestSyncError.noDataToSync
        }
        
        do {
            try await batch.commit()
            let now = Date()
            _ = dataManager.updateLastSyncCloudTime(date: now, contextType: .main)
            lastSyncSubject.send(now)
        } catch {
            throw ForestSyncError.firestoreError(error)
        }
    }
    
    func treePayload(_ tree: TreeModel) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.idField: tree.id.uuidString,
            ForestSyncConstants.typeField: ForestSyncConstants.plantType,
            ForestSyncConstants.assetNameField: tree.assetName,
            ForestSyncConstants.characterNameField: tree.characterName,
            ForestSyncConstants.xPositionField: tree.xPosition,
            ForestSyncConstants.yPositionField: tree.yPosition,
            ForestSyncConstants.isAliveField: tree.isAlive,
            ForestSyncConstants.healthValueField: tree.treeHealthValue,
            ForestSyncConstants.createdDateField: tree.createdDate,
            ForestSyncConstants.lastUpdatedDateField: tree.lastUpdatedDate
        ]
        if let rewardId = tree.rewardId {
            payload[ForestSyncConstants.rewardIdField] = rewardId
        }
        return payload
    }
    
    func animalPayload(_ animal: AnimalModel) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.idField: animal.id.uuidString,
            ForestSyncConstants.typeField: ForestSyncConstants.animalType,
            ForestSyncConstants.assetNameField: animal.assetName,
            ForestSyncConstants.characterNameField: animal.characterName,
            ForestSyncConstants.xPositionField: animal.xPosition,
            ForestSyncConstants.yPositionField: animal.yPosition,
            ForestSyncConstants.isAliveField: animal.isAlive,
            ForestSyncConstants.healthValueField: animal.healthValue,
            ForestSyncConstants.createdDateField: animal.createdDate,
            ForestSyncConstants.lastUpdatedDateField: animal.lastUpdatedDate
        ]
        if let rewardId = animal.rewardId {
            payload[ForestSyncConstants.rewardIdField] = rewardId
        }
        return payload
    }
    
    func sculpturePayload(_ sculpture: SculptureModel) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.idField: sculpture.id.uuidString,
            ForestSyncConstants.typeField: ForestSyncConstants.sculptureType,
            ForestSyncConstants.assetNameField: sculpture.assetName,
            ForestSyncConstants.characterNameField: sculpture.characterName,
            ForestSyncConstants.xPositionField: sculpture.xPosition,
            ForestSyncConstants.yPositionField: sculpture.yPosition,
            ForestSyncConstants.createdDateField: sculpture.createdDate,
            ForestSyncConstants.lastUpdatedDateField: sculpture.lastUpdatedDate
        ]
        if let rewardId = sculpture.rewardId {
            payload[ForestSyncConstants.rewardIdField] = rewardId
        }
        return payload
    }
    
    func questPayload(_ quest: QuestTrackModel) -> [String: Any] {
        [
            ForestSyncConstants.idField: quest.id,
            ForestSyncConstants.statusField: quest.status.valueForCoreData,
            ForestSyncConstants.currentProgressCountField: quest.currentProgressCount,
            ForestSyncConstants.lastUpdatedDateField: quest.lastUpdatedDate
        ]
    }
    
    func playerPayload(_ player: PlayerModel) -> [String: Any] {
        [
            ForestSyncConstants.nameField: player.name,
            ForestSyncConstants.lastUpdatedDateField: player.lastUpdateDate
        ]
    }
    
    func dailyActivitiesPayload(_ daily: DailyActivitiesModel) -> [String: Any] {
        var payload: [String: Any] = [
            ForestSyncConstants.weeklyStreakCurrentDayField: daily.weeklyStreakCurrentDay,
            ForestSyncConstants.monthlyLongLearnedCountField: daily.monthlyLongLearnedCount,
            ForestSyncConstants.monthlyShortLearnedCountField: daily.monthlyShortLearnedCount,
            ForestSyncConstants.fixedTimeZoneField: daily.fixedTimeZone ?? TimeZone.current.identifier,
            ForestSyncConstants.lastUpdatedDateField: daily.lastUpdatedDate,
            ForestSyncConstants.dailyKillGoldCountField: daily.dailyKillGoldCount
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
