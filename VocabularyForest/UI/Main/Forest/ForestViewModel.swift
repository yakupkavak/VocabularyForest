//
//  ForestViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import Foundation
import Combine
import YKSpinWheel

// MARK: - PROTOCOLS

protocol ForestViewModelOutputProcotol: AnyObject {
    func startFade()
    func startDrought()
    func startRain()
    func stopRain()
    func setupAnimal(animal: AnimalModel?)
    func setupSculpture(sculpture: SculptureModel)
    func setupPlant(plant: TreeModel)
    func talkComponent(type model: ComponentType, id: UUID, message: String)
    func updateAnnouncementClaimable(_ isClaimable: Bool)
}

protocol ForestViewModelProtocol: AnyObject {
    func startGameMusic()
    func stopGameMusic()
    func updateAudioSettings(music: Double, sfx: Double, isMuted: Bool)
    func playSoundEffect(name: String)
    func didTapTree(id: UUID)
    func didCollectWater(amount: Int)
    func fetchForest()
    func refreshForestStatus()
    func claimQuestReward(quest: QuestModel)
    func startRain()
    func checkBookCount(type: BattleQuestionType,
                        battleMode: BattleEnemyModel,
                        gameLevel: GameLevel,
                        bookcaseSelection: GameBookcaseSelection) -> Bool
    func closeBookError()
    func updateComponentName(name: String)
    func setComponent(uuid: UUID, for componentType: ComponentType)
    func fetchWeeklyDailyCards()
    func fetchAdventureRoadData()
}

// MARK: - VIEW MODEL

class ForestViewModel: BaseViewModel {
    
    private let coreDataManager: CoreDataManagerProtocol
    private let audioService: AudioServiceProtocol
    private let forestDataManager: ForestDataManagerProtocol
    private let forestEntityService: ForestEntityServiceProtocol
    private let adventureService: ForestAdventureServiceProtocol
    private let remoteConfigRepository: RemoteConfigRepositoryProtocol
    private let playerDataManager: PlayerDataManagerProtocol
    private let questService: QuestServiceProtocol
    private let dailySpinService: DailySpinServiceProtocol
    private let weeklyRewardService: WeeklyRewardServiceProtocol
    private let adventureRoadService: AdventureRoadServiceProtocol
    private let marketService: MarketServiceProtocol
    private let assetHydrationService: RewardAssetHydrationServiceProtocol

    // MARK: - PROPERTIES
    
    @Published var dailyQuestList: [QuestModel] = []
    @Published var weeklyQuestList: [QuestModel] = []
    @Published var monthlyQuestList: [QuestModel] = []
    @Published var specialQuestList: [QuestModel] = []
    @Published var bookcaseList: [BookcaseModel] = []
    @Published var forestStatus: ForestStatusModel? = nil
    @Published var showRainButton = false
    @Published var showBookThreshold = false
    @Published var weeklyDailyCards: [WeeklyDailyCardModel] = []
    @Published var dailySpinTime: Date? = nil
    @Published var dailySpinModels: [SpinModel] = []
    @Published var dailySpinModelVersion = UUID()
    @Published var adventureRoadScreenModel: AdventureRoadScreenModel? = nil
    @Published var marketScreenModel: MarketScreenModel? = nil
    @Published var marketErrorMessage: String? = nil
    @Published private(set) var isDailySpinClaimable = false
    private var nextDailySpinTime: Date? = nil
    private var animalList: [AnimalModel] = []
    private var sculptureList: [SculptureModel] = []
    private var treeList: [TreeModel] = []
    private var componentUUID: UUID? = nil
    private var selectedModel: ComponentType? = nil
    private var directionList: [DirectionWithCount] = []
    private var dailySpinRewardMap: [Int: LocalRewardType] = [:]
    private var fetchForestTask: Task<Void, Error>? = nil
    /// Latest rewards catalog, kept for resolving entity render sizes (rewards_config ratios).
    private var rewardCatalogResolver = RewardCatalogResolver(items: [])
    weak var output: ForestViewModelOutputProcotol?
    
    private let logger: AppLoggerProtocol
    private var talkCancellable: AnyCancellable?
    private var dailyTimeCancellable: AnyCancellable?
    private var rainTimeCancellable: AnyCancellable?
    private var questCancellable = Set<AnyCancellable>()
    private var adventureCancellable = Set<AnyCancellable>()
    private var hydrationCancellable = Set<AnyCancellable>()

    // MARK: - INIT
    
    init(
        audioService: AudioServiceProtocol,
        coreDataManager: CoreDataManagerProtocol,
        forestDataManager: ForestDataManagerProtocol,
        forestEntityService: ForestEntityServiceProtocol,
        forestAdventureService: ForestAdventureServiceProtocol,
        remoteConfigRepository: RemoteConfigRepositoryProtocol,
        playerDataManager: PlayerDataManagerProtocol,
        questService: QuestServiceProtocol,
        dailySpinService: DailySpinServiceProtocol,
        weeklyRewardService: WeeklyRewardServiceProtocol,
        adventureRoadService: AdventureRoadServiceProtocol,
        marketService: MarketServiceProtocol,
        assetHydrationService: RewardAssetHydrationServiceProtocol,
        logger: AppLoggerProtocol = AppLogger.shared
    ) {
        self.audioService = audioService
        self.coreDataManager = coreDataManager
        self.forestDataManager = forestDataManager
        self.forestEntityService = forestEntityService
        self.adventureService = forestAdventureService
        self.remoteConfigRepository = remoteConfigRepository
        self.playerDataManager = playerDataManager
        self.questService = questService
        self.dailySpinService = dailySpinService
        self.weeklyRewardService = weeklyRewardService
        self.adventureRoadService = adventureRoadService
        self.marketService = marketService
        self.assetHydrationService = assetHydrationService
        self.logger = logger
        super.init()
        bindQuests()
        bindDailySpin()
        bindWeeklyRewards()
        bindAdventureRoad()
        bindMarket()
        bindAssetHydration()
        fetchForest()
    }
}

// MARK: - BOOK HELPERS

extension ForestViewModel {
    
    func closeBookError() {
        showBookThreshold = false
    }
    
    func checkBookCount(
        type: BattleQuestionType,
        battleMode: BattleEnemyModel,
        gameLevel: GameLevel,
        bookcaseSelection: GameBookcaseSelection
    ) -> Bool {
        let minBook = calculateMinBookCount(battleMode: battleMode, gameLevel: gameLevel)
        if type == .learning {
            switch bookcaseSelection {
            case .allBookcases:
                guard let books = coreDataManager.fetchAllBooksWithExampleDescription(
                    bookLimit: minBook, sortDescriptors: nil,
                    contextType: .background
                ) else {
                    showBookThreshold = true
                    return false }
                if books.filter({ $0.shortMemory == true }).count < minBook {
                    showBookThreshold = true
                    return false
                }
            case .spesific(let bookcase):
                guard let books = coreDataManager.fetchSafeBooksExampleDescription(
                    model: bookcase,
                    sortDescriptors: nil,
                    contextType: .background
                ) else {
                    showBookThreshold = true
                    return false }
                if books.filter({ $0.shortMemory == true }).count < minBook {
                    showBookThreshold = true
                    return false
                }
            }
        }
        else {
            switch bookcaseSelection {
            case .allBookcases:
                if type == .competitive {
                    guard let isEnoughBook = coreDataManager.askIsEnoughtLimitedSafeBooks(bookCount: minBook, memoryType: .short, contextType: .background) else {
                        showBookThreshold = true
                        return false
                    }
                    if !isEnoughBook {
                        showBookThreshold = true
                        return false
                    }
                }else { // remainder
                    guard let isEnoughBook = coreDataManager.askIsEnoughtLimitedSafeBooks(bookCount: minBook, memoryType: .long, contextType: .background) else {
                        showBookThreshold = true
                        return false
                    }
                    if !isEnoughBook {
                        showBookThreshold = true
                        return false
                    }
                }
            case .spesific(let bookcase):
                guard let books = coreDataManager.fetchBooks(
                    model: bookcase,
                    sortDescriptors: nil,
                    contextType: .background
                ) else {
                    showBookThreshold = true
                    return false }
                if type == .competitive {
                    if books.filter({ $0.shortMemory == true }).count < minBook {
                        showBookThreshold = true
                        return false
                    }
                }else {
                    if books.filter({ $0.longMemory == true }).count < minBook {
                        showBookThreshold = true
                        return false
                    }
                }
            }
        }
        return true
    }
}

// MARK: - FOREST HELPERS

extension ForestViewModel {
    
    var claimableAnnouncementTypes: Set<AnnouncementTypeModel> {
        var types: Set<AnnouncementTypeModel> = []
        let allQuests = dailyQuestList + weeklyQuestList + monthlyQuestList + specialQuestList
        if allQuests.contains(where: { $0.status == .completed }) {
            types.insert(.tasks)
        }
        if weeklyDailyCards.contains(where: { $0.status == .ready }) {
            types.insert(.dailyReward)
        }
        if isDailySpinClaimable {
            types.insert(.dailySpin)
        }
        let hasAdventureReward = adventureRoadScreenModel?.rows.contains {
            $0.leftMilestone.status == .ready || $0.rightMilestone.status == .ready
        } ?? false
        if hasAdventureReward {
            types.insert(.adventureRoad)
        }
        return types
    }
    
    func fetchWeeklyDailyCards() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            await weeklyRewardService.checkAndUpdateWeeklyState()
        }
    }
    
    func initalizeForest() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            animalList.removeAll()
            sculptureList.removeAll()
            treeList.removeAll()
            fetchForest()
            hydratePendingAssets()
            checkDailySpinStatus()
            refreshDailySpinRewards()
            fetchWeeklyDailyCards()
            fetchAdventureRoadData()
        }
    }
    
    func hydratePendingAssets() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            // Try to download the queued entities (assetReady == false): this is where the user is
            // most likely to notice something missing. Idempotent, ready assets skip the network.
            await assetHydrationService.hydratePendingAssets()
        }
    }

    func checkDailySpinStatus() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            await dailySpinService.checkAndUpdateSpinState()
        }
    }
    
    func refreshDailySpinRewards() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            /*
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.dailySpinModels = models
                self.dailySpinRewardMap = rewardMap
                self.dailySpinModelVersion = UUID()
            }
             */
        }
    }
    
    func resolveDailySpinReward(from spinModel: SpinModel) -> LocalRewardModel? {
        do {
            return try dailySpinService.convertLocalReward(model: spinModel)
        }catch {
            logger.error("Daily spin reward could not be resolved: \(error.localizedDescription)", category: .reward)
        }
        return nil
    }
    
    func fetchAdventureRoadData() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            await adventureRoadService.checkAndUpdateAdventureState()
        }
    }
    
    func fetchForest() {
        let forestInitalized = UserDefaults.standard.bool(forKey: "forestInitalized")

        let previousTask = fetchForestTask
        fetchForestTask = Task(priority: .background) { [weak self] in
            // Ayni anda birden fazla fetch calisip eski verinin yeniyi ezmesini engelle
            if let previousTask { _ = try? await previousTask.value }
            guard let self else { return }
            
            if !forestInitalized {
                // TODO: - CREATE FOREST IF NOT CREATED
            }
            
            // Status is fetched first so an entity fetch failure below can never leave
            // forestStatus nil (the info popup shows an error state when it is).
            let forestData: ForestStatusModel
            do {
                forestData = try forestDataManager.fetchForestStatus(contextType: .background)
            } catch {
                logger.error("Forest status could not be fetched: \(error.localizedDescription)", category: .forest)
                return
            }

            // Entities with assetReady == false never enter the scene; once hydration finishes,
            // fetchForest is triggered again and the missing ones appear on their own.
            var fetchedAnimals: [AnimalModel] = []
            var fetchedSculptures: [SculptureModel] = []
            do {
                fetchedAnimals = try forestEntityService.fetchAnimals(contextType: .background).filter { $0.assetReady }
                fetchedSculptures = try forestEntityService.fetchSculptures(contextType: .background).filter { $0.assetReady }
            } catch {
                logger.error("Forest entities could not be fetched: \(error.localizedDescription)", category: .forest)
            }
            let fetchedTrees = (forestEntityService.fetchTrees(contextType: .background).data ?? []).filter { $0.assetReady }
            let fetchedBookcases = coreDataManager.fetchSafeBookcases(
                sortDescriptors: nil,
                contextType: .background
            )
            let catalogResolver = await fetchRewardCatalogResolver()

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.rewardCatalogResolver = catalogResolver

                let newAnimals = fetchedAnimals.filter { newItem in
                    !animalList.contains(where: { $0 == newItem })
                }
                
                let newSculptures = fetchedSculptures.filter { newItem in
                    !sculptureList.contains(where: { $0 == newItem })
                }
                
                let newTrees = fetchedTrees.filter { newItem in
                    !treeList.contains(where: { $0 == newItem })
                }
                
                if let cases = fetchedBookcases {
                    bookcaseList = cases
                }

                if !newAnimals.isEmpty { animalList.append(contentsOf: newAnimals) }
                if !newSculptures.isEmpty { sculptureList.append(contentsOf: newSculptures) }
                if !newTrees.isEmpty { treeList.append(contentsOf: newTrees) }

                for animal in newAnimals {
                    output?.setupAnimal(animal: applyingRewardSizes(animal))
                }

                for sculpture in newSculptures {
                    output?.setupSculpture(sculpture: applyingRewardSizes(sculpture))
                }

                for tree in newTrees {
                    output?.setupPlant(plant: applyingRewardSizes(tree))
                }

                forestStatus = ForestStatusModel(
                    rainValue: forestData.rainValue,
                    landHealthPercentage: forestData.landHealthPercentage,
                    landStatus: forestData.landStatus,
                    gold: forestData.gold,
                    diamond: forestData.diamond
                )
                
                if forestData.rainValue >= ForestConstant.rainCostValue { self.showRainButton = true }
                
                if let landHealthPercentage = forestStatus?.landHealthPercentage {
                    if landHealthPercentage == 0 {
                        output?.startDrought()
                    } else if landHealthPercentage <= 50 {
                        output?.startFade()
                    }
                }
                
                startRandomTalking()
            }
        }
    }
    
    /// Lightweight refresh used by the info popup; fetchForest may still be in flight
    /// (or may have failed) when the popup opens, so the status is re-read on demand.
    func refreshForestStatus() {
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let status = try forestDataManager.fetchForestStatus(contextType: .background)
                await MainActor.run { self.forestStatus = status }
            } catch {
                logger.error("Forest status refresh failed: \(error.localizedDescription)", category: .forest)
            }
        }
    }

    func startRain() {
        showRainButton = false
        output?.startRain()
        try? forestDataManager.startRain(contextType: .background)
        var time = 0
        
        rainTimeCancellable?.cancel()
        rainTimeCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                time += 1
                if time == 40 {
                    output?.stopRain()
                    rainTimeCancellable?.cancel()
                }
            }
    }
}

// MARK: - SOUND HELPERS

extension ForestViewModel {
    func startGameMusic() {
        audioService.playBackgroundMusic()
    }
    
    func stopGameMusic() {
        audioService.stopMusic()
    }

    func updateAudioSettings(music: Double, sfx: Double, isMuted: Bool) {
        audioService.updateVolume(musicLevel: music, sfxLevel: sfx, isMuted: isMuted)
    }
    
    func playSoundEffect(name: String) {
        audioService.playSFX(filename: name)
    }

    func didTapTree(id: UUID) {
        playSoundEffect(name: "pop_sound")
    }

    func didCollectWater(amount: Int) {
        playSoundEffect(name: "water_splash")
    }
}

// MARK: - FOREST VIEW MODEL PROTOCOL

extension ForestViewModel: ForestViewModelProtocol {
    
    func setComponent(uuid: UUID, for componentType: ComponentType) {
        componentUUID = uuid
        selectedModel = componentType
    }
    
    func updateComponentName(name: String) {
        guard let selectedModel else { return }
        guard let componentUUID else { return }
        let result = forestEntityService.updateComponentName(
            id: componentUUID,
            type: selectedModel,
            newName: name,
            contextType: .background
        )
        if result.status == .success {
            switch selectedModel {
            case .animal:
                if let model = forestEntityService.fetchAnimal(id: componentUUID, contextType: .background) {
                    self.output?.setupAnimal(animal: applyingRewardSizes(model))
                }
                if let index = animalList.firstIndex(where: { $0.id == componentUUID }) {
                    animalList[index].characterName = name
                }
            case .plant:
                if let model = forestEntityService.fetchPlant(id: componentUUID, contextType: .background) {
                    self.output?.setupPlant(plant: applyingRewardSizes(model))
                }
                if let index = treeList.firstIndex(where: { $0.id == componentUUID }) {
                    treeList[index].characterName = name
                }
            case .sculpture:
                if let model = forestEntityService.fetchSculpture(id: componentUUID, contextType: .background) {
                    self.output?.setupSculpture(sculpture: applyingRewardSizes(model))
                }
                if let index = sculptureList.firstIndex(where: { $0.id == componentUUID }) {
                    sculptureList[index].characterName = name
                }
            }
        }
        self.selectedModel = nil
        self.componentUUID = nil
    }
    
    func claimQuestReward(quest: QuestModel) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await adventureService.claimQuestReward(quest: quest)
                await MainActor.run {
                    self.fetchForest()
                }
            } catch {
                logger.error("Quest reward claim failed: \(error.localizedDescription)", category: .reward)
            }
        }
    }
    
    func claimLocalReward(model: LocalRewardModel, onSuccess: (() -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await adventureService.claimLocalReward(model: model)
                await MainActor.run {
                    onSuccess?()
                    self.fetchForest()
                }
            } catch {
                logger.error("Local reward claim failed: \(error.localizedDescription)", category: .reward)
            }
        }
    }
    
    func claimDailyRewards(models: [LocalRewardModel]) {
        Task { @MainActor in
            do {
                for model in models {
                    try await adventureService.claimDailySpinReward(model: model)
                }
                self.fetchForest()
            } catch {
                logger.error("Daily spin rewards claim failed: \(error.localizedDescription)", category: .reward)
            }
        }
    }
    
    func claimWeeklyRewards(models: [LocalRewardModel], weeklyModel: WeeklyDailyCardModel) {
        Task { @MainActor in
            do {
                try await adventureService.claimWeeklyReward(models: models, weeklyModel: weeklyModel)
                self.fetchForest()
            } catch {
                logger.error("Weekly reward claim failed: \(error.localizedDescription)", category: .reward)
            }
        }
    }
    
    func claimAdventureRewards(models: [LocalRewardModel], milestone: AdventureMilestoneModel) {
        Task { @MainActor in
            do {
                try await adventureService.claimAdventureReward(models: models, milestone: milestone)
                self.fetchForest()
            } catch {
                logger.error("Adventure reward claim failed: \(error.localizedDescription)", category: .reward)
            }
        }
    }
    
    func purchaseMarketItem(item: MarketItemModel, onSuccess: @escaping () -> Void) {
        Task { @MainActor in
            do {
                try await adventureService.purchaseMarketItem(item: item)
                marketErrorMessage = nil
                fetchForest()
                onSuccess()
            } catch {
                marketErrorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchChestDropInfo(chestId: String) async -> [ChestDropInfoModel]? {
        do {
            return try await adventureService.fetchChestDropInfo(chestId: chestId)
        } catch {
            logger.error("Chest drop info fetch failed for chest \(chestId): \(error.localizedDescription)", category: .reward)
            return nil
        }
    }
    
    func claimMarketRewards(models: [LocalRewardModel]) {
        Task { @MainActor in
            do {
                for model in models {
                    try await adventureService.claimLocalReward(model: model)
                }
                self.fetchForest()
            } catch {
                logger.error("Market rewards claim failed: \(error.localizedDescription)", category: .reward)
            }
        }
    }
}

// MARK: - FOREST SCENE PROTOCOL

extension ForestViewModel: ForectSceneProtocol {
    func updatePosition(model: ComponentModelProtocol, directionList: [DirectionWithCount]) {
        var xValue = model.xPosition
        var yValue = model.yPosition
        for direction in directionList {
            switch direction.direction {
            case .up:
                yValue += CGFloat(direction.count) * ForestConstant.perVerticalMove
            case .down:
                yValue -= CGFloat(direction.count) * ForestConstant.perVerticalMove
            case .right:
                xValue += CGFloat(direction.count) * ForestConstant.perHorizontalMove
            case .left:
                xValue -= CGFloat(direction.count) * ForestConstant.perHorizontalMove
            }
        }
        forestEntityService.updateComponentPosition(
            model: model,
            xValue: xValue,
            yValue: yValue,
            contextType: .background
        )
    }
}

// MARK: - RANDOM TALK HELPERS

private extension ForestViewModel {

    func startRandomTalking() {
        stopRandomTalking()
        
        talkCancellable = Timer.publish(every: 20.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.triggerRandomTalk()
            }
    }
    
    func stopRandomTalking() {
        talkCancellable?.cancel()
        talkCancellable = nil
    }
    
    func triggerRandomTalk() {
            guard let status = forestStatus else { return }
            let isDrought = status.landHealthPercentage == 0
            
            var availableTypes: [ComponentType] = []
            if !animalList.isEmpty { availableTypes.append(.animal) }
            if !treeList.isEmpty { availableTypes.append(.plant) }
            if !sculptureList.isEmpty { availableTypes.append(.sculpture) }
            
            guard let selectedType = availableTypes.randomElement() else { return }
            
            var targetID: UUID?
            var message: String = ""
            
            switch selectedType {
            case .animal:
                guard let randomAnimal = animalList.randomElement() else { return }
                targetID = randomAnimal.id
                message = isDrought ?
                    TalkConstant.Animal.drought.randomElement()! :
                    TalkConstant.Animal.normal.randomElement()!
                
            case .plant:
                guard let randomTree = treeList.randomElement() else { return }
                targetID = randomTree.id
                message = isDrought ?
                    TalkConstant.Plant.drought.randomElement()! :
                    TalkConstant.Plant.normal.randomElement()!
                
            case .sculpture:
                guard let randomSculpture = sculptureList.randomElement() else { return }
                targetID = randomSculpture.id
                message = isDrought ?
                    TalkConstant.Sculpture.drought.randomElement()! :
                    TalkConstant.Sculpture.normal.randomElement()!
            }
            
            if let id = targetID {
                output?.talkComponent(type: selectedType, id: id, message: message)
            }
        }
}

// MARK: - PRIVATE HELPERS

private extension ForestViewModel {

    func fetchRewardCatalogResolver() async -> RewardCatalogResolver {
        do {
            let response = try await remoteConfigRepository.fetchRewardsCatalog()
            return RewardCatalogResolver(items: response.model.items ?? [])
        } catch {
            logger.error("Rewards catalog could not be fetched for sizing: \(error.localizedDescription)", category: .forest)
            return RewardCatalogResolver(items: [])
        }
    }

    /// Copies the rewards_config size ratios onto the model handed to the scene;
    /// stored lists stay untouched so Equatable-based dedup keeps working.
    func applyingRewardSizes<Model: ComponentModelProtocol>(_ model: Model) -> Model {
        guard let item = rewardCatalogResolver.catalogItem(rewardId: model.rewardId, assetName: model.assetName) else {
            return model
        }
        var sizedModel = model
        sizedModel.widthRatio = item.widthRatio.map { CGFloat($0) }
        sizedModel.heightRatio = item.heightRatio.map { CGFloat($0) }
        return sizedModel
    }

    func bindQuests() {
        questService.questListPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] updatedQuests in
                guard let self else { return }
                dailyQuestList = updatedQuests.filter {  $0.type == .daily }
                weeklyQuestList = updatedQuests.filter {  $0.type == .weekly }
                monthlyQuestList = updatedQuests.filter {  $0.type == .monthly }
                specialQuestList = updatedQuests.filter {  $0.type == .special }
                notifyAnnouncementClaimState()
            }.store(in: &questCancellable)
    }
    
    func bindDailySpin() {
        dailySpinService.dailySpinListPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] models in
                guard let self else { return }
                dailySpinModels = models
                dailySpinModelVersion = UUID()
            }.store(in: &adventureCancellable)
        
        dailySpinService.dailySpinStatePublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .claimable:
                    dailyTimeCancellable?.cancel()
                    nextDailySpinTime = nil
                    dailySpinTime = nil
                    isDailySpinClaimable = true
                case .alreadyClaimed(let remainSeconds):
                    nextDailySpinTime = Date().addingTimeInterval(remainSeconds)
                    dailySpinTime = Calendar.current.startOfDay(for: Date()).addingTimeInterval(remainSeconds)
                    startDailySpinTimer()
                    isDailySpinClaimable = false
                }
                notifyAnnouncementClaimState()
            }.store(in: &adventureCancellable)
    }
    
    func bindWeeklyRewards() {
        weeklyRewardService.weeklyCardListPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] cards in
                guard let self else { return }
                weeklyDailyCards = cards
                notifyAnnouncementClaimState()
            }.store(in: &adventureCancellable)
    }
    
    func bindAdventureRoad() {
        adventureRoadService.adventureScreenModelPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                guard let self else { return }
                adventureRoadScreenModel = model
                notifyAnnouncementClaimState()
            }.store(in: &adventureCancellable)
    }
    
    func bindAssetHydration() {
        assetHydrationService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                // Refresh the scene when hydration marked at least one asset ready; ForestScene
                // returns early on an id match, so a repeated call does not create duplicates.
                if case .finished(let summary) = state, summary.readyCount > 0 {
                    fetchForest()
                }
            }.store(in: &hydrationCancellable)
    }

    func bindMarket() {
        marketService.marketScreenModelPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                guard let self else { return }
                marketScreenModel = model
            }.store(in: &adventureCancellable)
    }
    
    func notifyAnnouncementClaimState() {
        output?.updateAnnouncementClaimable(!claimableAnnouncementTypes.isEmpty)
    }
    
    func startDailySpinTimer() {
        dailyTimeCancellable?.cancel()
        dailyTimeCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            guard let self = self, let target = self.nextDailySpinTime else { return }
            if Date() >= target {
                self.nextDailySpinTime = nil
                self.dailySpinTime = nil
                self.dailyTimeCancellable?.cancel()
            } else {
                if let currentSpinTime = self.dailySpinTime {
                    self.dailySpinTime = currentSpinTime.addingTimeInterval(-1)
                }
            }
        }
    }
    
    func processQuests(quests: [QuestModel]) {
        var daily: [QuestModel] = []
        var weekly: [QuestModel] = []
        var monthly: [QuestModel] = []
        var special: [QuestModel] = []
        
        for quest in quests {
            switch quest.type {
            case .daily: daily.append(quest)
            case .weekly: weekly.append(quest)
            case .monthly: monthly.append(quest)
            case .special: special.append(quest)
            }
        }
        
        self.dailyQuestList = daily
        self.weeklyQuestList = weekly
        self.monthlyQuestList = monthly
        self.specialQuestList = special
    }
}
