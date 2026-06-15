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
}

protocol ForestViewModelProtocol: AnyObject {
    func startGameMusic()
    func stopGameMusic()
    func updateAudioSettings(music: Double, sfx: Double, isMuted: Bool)
    func playSoundEffect(name: String)
    func didTapTree(id: UUID)
    func didCollectWater(amount: Int)
    func fetchForest()
    func claimReward(quest: QuestModel)
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
    //@Published var adventureRoadScreenModel: AdventureRoadScreenModel = AdventureRoadMockData.screenModel()
    @Published var adventureRoadSeasonLeftTime: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    private var nextDailySpinTime: Date? = nil
    private var animalList: [AnimalModel] = []
    private var sculptureList: [SculptureModel] = []
    private var treeList: [TreeModel] = []
    private var componentUUID: UUID? = nil
    private var selectedModel: ComponentType? = nil
    private var directionList: [DirectionWithCount] = []
    private var dailySpinRewardMap: [Int: LocalRewardType] = [:]
    weak var output: ForestViewModelOutputProcotol?
    
    private var talkCancellable: AnyCancellable?
    private var dailyTimeCancellable: AnyCancellable?
    private var rainTimeCancellable: AnyCancellable?
    private var questCancellable = Set<AnyCancellable>()

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
    ) {
        self.audioService = audioService
        self.coreDataManager = coreDataManager
        self.forestDataManager = forestDataManager
        self.forestEntityService = forestEntityService
        self.adventureService = forestAdventureService
        self.remoteConfigRepository = remoteConfigRepository
        self.playerDataManager = playerDataManager
        self.questService = questService
        super.init()
        bindQuests()
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
                    sortDescriptors: nil,
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
                guard let books = coreDataManager.fetchAllSafeBooks(contextType: .background) else {
                    showBookThreshold = true
                    return false }
                if type == .competitive {
                    if books.filter({ $0.shortMemory == true }).count < minBook {
                        showBookThreshold = true
                        return false
                    }
                }else { // remainder
                    if books.filter({ $0.longMemory == true }).count < minBook {
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
    
    func fetchWeeklyDailyCards() {
        /*
        Task { @MainActor in
            let result = await adventureService.fetchWeeklyDailyRewards()
            if result.status == .success, let cards = result.data {
                self.weeklyDailyCards = cards
            } else {
                print("Hata: Haftalık kartlar çekilemedi -> \(result.error?.localizedDescription ?? "")")
            }
        }
         */
    }
    
    func initalizeForest() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            animalList.removeAll()
            sculptureList.removeAll()
            treeList.removeAll()
            fetchForest()
            checkDailySpinStatus()
            refreshDailySpinRewards()
            fetchWeeklyDailyCards()
            fetchAdventureRoadData()
        }
    }
    
    func refreshDailySpinRewards() {
        /*
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            let result = await remoteConfigRepository.fetchDailySpinRewards()
            guard result.status == .success, let rewards = result.data else { return }
            let (models, rewardMap) = RewardHelper.createDailySpinWheel(from: rewards)
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.dailySpinModels = models
                self.dailySpinRewardMap = rewardMap
                self.dailySpinModelVersion = UUID()
            }
        }
         */
    }
    /*
    func resolveDailySpinReward(from spinModel: SpinModel) -> LocalRewardType {
        dailySpinRewardMap[spinModel.id] ?? RewardHelper.convertDailyRewardModel(from: spinModel)
    }
    */
    func fetchAdventureRoadData() {
        /*
        Task { @MainActor in
            let trueNow = (try? await NetworkTimeHelper.getTrueTime()) ?? Date()
            var configResult = await remoteConfigRepository.fetchAdventureRoadConfig()
            
            if let config = configResult.data, trueNow >= config.seasonEndDate {
                configResult = await remoteConfigRepository.fetchAdventureRoadConfig()
            }
            
            let progress = playerDataManager.fetchAdventureRoadProgress(contextType: .main) ?? AdventureRoadProgressModel(
                seasonID: nil,
                monthlyShortLearnedCount: 0,
                monthlyLongLearnedCount: 0
            )
            
            guard configResult.status == .success, let config = configResult.data else {
                adventureRoadScreenModel = AdventureRoadMockData.screenModel()
                adventureRoadSeasonLeftTime = adventureRoadScreenModel.eventEndDate
                return
            }
            
            adventureRoadScreenModel = AdventureRoadBuilder.screenModel(
                rewards: config.rewards,
                progress: progress,
                eventEndDate: config.seasonEndDate,
                referenceDate: trueNow
            )
            adventureRoadSeasonLeftTime = config.seasonEndDate
        }
         */
    }
    
    func fetchForest() {
        let forestInitalized = UserDefaults.standard.bool(forKey: "forestInitalized")

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            
            if !forestInitalized {
                // TODO: - CREATE FOREST IF NOT CREATED
            }
            
            let fetchedAnimals = try forestEntityService.fetchAnimals(contextType: .background)
            let fetchedSculptures = try forestEntityService.fetchSculptures(contextType: .background)
            let fetchedTrees = forestEntityService.fetchTrees(contextType: .background).data ?? []
            let fetchedBookcases = coreDataManager.fetchSafeBookcases(
                sortDescriptors: nil,
                contextType: .background
            )
            guard let forestData = try? forestDataManager.fetchForestStatus(contextType: .background) else {
                return
            }

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
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
                    output?.setupAnimal(animal: animal)
                }
                
                for sculpture in newSculptures {
                    output?.setupSculpture(sculpture: sculpture)
                }
                
                for tree in newTrees {
                    output?.setupPlant(plant: tree)
                }
                
                forestStatus = ForestStatusModel(
                    rainValue: forestData.rainValue,
                    landHealthPercentage: forestData.landHealthPercentage,
                    landStatus: forestData.landStatus,
                    gold: forestData.gold
                )
                
                if forestData.rainValue >= 50 { self.showRainButton = true }
                
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
                    self.output?.setupAnimal(animal: model)
                }
            case .plant:
                if let model = forestEntityService.fetchPlant(id: componentUUID, contextType: .background) {
                    self.output?.setupPlant(plant: model)
                }
            case .sculpture:
                if let model = forestEntityService.fetchSculpture(id: componentUUID, contextType: .background) {
                    self.output?.setupSculpture(sculpture: model)
                }
            }
        }
        self.selectedModel = nil
        self.componentUUID = nil
    }
    
    func claimReward(quest: QuestModel) {
        do {
            try adventureService.claimQuestReward(quest: quest)
            fetchForest()
        }catch {
            print("\(error.localizedDescription)")
        }
    }
    
    func claimDailyReward(model: QuestRewardModel) {
        /*
        Task { @MainActor in
            let result = await adventureService.claimDailySpinReward(reward: model, contextType: .main)
            if result.status == .success {
                let target = Date().addingTimeInterval(86400)
                self.nextDailySpinTime = target
                self.dailySpinTime = target
                self.startDailySpinTimer()
            }
        }
        */
    }
    
    func claimWeeklyReward(reward: LocalQuestRewardModel, weeklyModel:  WeeklyDailyCardModel) {
        /*
        Task { @MainActor in
            let result = await adventureService.saveWeeklyReward(weeklyModel: weeklyModel, contextType: .main)
            let _ = forestDataManager.claimReward(model: reward, contextType: .main)
            if result.status == .success {
                if let index = self.weeklyDailyCards.firstIndex(where: { $0.day == weeklyModel.day }) {
                    self.weeklyDailyCards[index].status = .claimed
                }
            }
        }
         */
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
    
    func bindQuests() {
        questService.questListPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] updatedQuests in
                guard let self else { return }
                dailyQuestList = updatedQuests.filter {  $0.type == .daily }
                weeklyQuestList = updatedQuests.filter {  $0.type == .weekly }
                monthlyQuestList = updatedQuests.filter {  $0.type == .monthly }
                specialQuestList = updatedQuests.filter {  $0.type == .special }
            }.store(in: &questCancellable)

    }
    
    func checkDailySpinStatus() {
        /*
        Task { @MainActor in
            let result = await adventureService.fetchDailySpinStatusDate()
            
            if let targetTime = result.data {
                self.nextDailySpinTime = targetTime
                self.dailySpinTime = targetTime
                self.startDailySpinTimer()
            }
        }
         */
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
