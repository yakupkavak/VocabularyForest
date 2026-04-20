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
}

// MARK: - VIEW MODEL

class ForestViewModel: BaseViewModel {
    
    // MARK: - DEPENDENCIES
    
    private let coreDataManager: CoreDataManagerProtocol
    private let audioService: AudioServiceProtocol
    private let forestDataManager: ForestDataManagerProtocol
    private let adventureService: ForestAdventureServiceProtocol
    
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
    @Published var nextDailySpinTime: Date? = nil
    private var animalList: [AnimalModel] = []
    private var sculptureList: [SculptureModel] = []
    private var treeList: [TreeModel] = []
    private var componentUUID: UUID? = nil
    private var selectedModel: ComponentType? = nil
    private var directionList: [DirectionWithCount] = []
    weak var output: ForestViewModelOutputProcotol?
    
    private var talkCancellable: AnyCancellable?
    private var dailyTimeCancellable: AnyCancellable?

    // MARK: - INIT
    
    init(
        audioService: AudioServiceProtocol,
        coreDataManager: CoreDataManagerProtocol,
        forestDataManager: ForestDataManagerProtocol,
        forestAdventureService: ForestAdventureServiceProtocol
    ) {
        self.audioService = audioService
        self.coreDataManager = coreDataManager
        self.forestDataManager = forestDataManager
        self.adventureService = forestAdventureService
        super.init()
        
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
    
    func initalizeForest() {
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            animalList.removeAll()
            sculptureList.removeAll()
            treeList.removeAll()
            fetchForest()
            checkDailySpinStatus()
        }
    }
    
    func fetchForest() {
        let forestInitalized = UserDefaults.standard.bool(forKey: "forestInitalized")

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            
            if !forestInitalized {
                // TODO: - CREATE FOREST IF NOT CREATED
            }
            
            let fetchedAnimals = forestDataManager.fetchAnimals(contextType: .background).data ?? []
            let fetchedSculptures = forestDataManager.fetchSculptures(contextType: .background).data ?? []
            let fetchedTrees = forestDataManager.fetchTrees(contextType: .background).data ?? []
            let fetchedBookcases = coreDataManager.fetchSafeBookcases(
                sortDescriptors: nil,
                contextType: .background
            )
            let statusResult = forestDataManager.fetchForestStatus(contextType: .background)
            let questResult = forestDataManager.fetchQuests(contextType: .background)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                let newAnimals = fetchedAnimals.filter { newItem in
                    !self.animalList.contains(where: { $0 == newItem })
                }
                
                let newSculptures = fetchedSculptures.filter { newItem in
                    !self.sculptureList.contains(where: { $0 == newItem })
                }
                
                let newTrees = fetchedTrees.filter { newItem in
                    !self.treeList.contains(where: { $0 == newItem })
                }
                
                if let cases = fetchedBookcases {
                    self.bookcaseList = cases
                }

                if !newAnimals.isEmpty { self.animalList.append(contentsOf: newAnimals) }
                if !newSculptures.isEmpty { self.sculptureList.append(contentsOf: newSculptures) }
                if !newTrees.isEmpty { self.treeList.append(contentsOf: newTrees) }

                for animal in newAnimals {
                    self.output?.setupAnimal(animal: animal)
                }
                
                for sculpture in newSculptures {
                    self.output?.setupSculpture(sculpture: sculpture)
                }
                
                for tree in newTrees {
                    self.output?.setupPlant(plant: tree)
                }
                
                if let quests = questResult.data {
                    self.processQuests(quests: quests)
                }
                
                if let forestData = statusResult.data {
                    self.forestStatus = ForestStatusModel(
                        rainValue: forestData.rainValue,
                        landHealthPercentage: forestData.landHealthPercentage,
                        landStatus: forestData.landStatus,
                        gold: forestData.gold
                    )
                    
                    if forestData.rainValue >= 50 { self.showRainButton = true }
                    
                    if let landHealthPercentage = self.forestStatus?.landHealthPercentage {
                        if landHealthPercentage == 0 {
                            self.output?.startDrought()
                        } else if landHealthPercentage <= 50 {
                            self.output?.startFade()
                        }
                    }
                }
                
                self.startRandomTalking()
            }
        }
    }
    
    func startRain() {
        showRainButton = false
        output?.startRain()
        forestDataManager.startRain(contextType: .background)
        var time = 0
        let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            time += 1
            if time == 40 {
                output?.stopRain()
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
        let result = forestDataManager.updateComponentName(
            id: componentUUID,
            type: selectedModel,
            newName: name,
            contextType: .background
        )
        if result.status == .success {
            switch selectedModel {
            case .animal:
                if let model = forestDataManager.fetchAnimal(id: componentUUID, contextType: .background) {
                    self.output?.setupAnimal(animal: model)
                }
            case .plant:
                if let model = forestDataManager.fetchPlant(id: componentUUID, contextType: .background) {
                    self.output?.setupPlant(plant: model)
                }
            case .sculpture:
                if let model = forestDataManager.fetchSculpture(id: componentUUID, contextType: .background) {
                    self.output?.setupSculpture(sculpture: model)
                }
            }
        }
        self.selectedModel = nil
        self.componentUUID = nil
    }
    
    func claimReward(quest: QuestModel) {
        let result = forestDataManager.claimQuestReward(quest: quest, contextType: .background)
        if result.status == .success {
            fetchForest()
        }
    }
    
    func claimReward(model: QuestRewardModel) {
        Task { @MainActor in
            let result = await adventureService.claimDailySpinReward(reward: model, contextType: .main)
            if result.status == .success {
                self.nextDailySpinTime = Date().addingTimeInterval(86400)
                self.startSpinTimer()                
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
        forestDataManager.updateComponentPosition(
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
    
    func checkDailySpinStatus() {
        Task { @MainActor in
            let result = await adventureService.fetchDailySpinStatusDate()
            
            if let targetTime = result.data {
                self.nextDailySpinTime = targetTime
                self.startSpinTimer()
            }
        }
    }
    
    func startSpinTimer() {
        dailyTimeCancellable?.cancel()
        dailyTimeCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let target = self.nextDailySpinTime else { return }
                
                if Date() >= target {
                    self.nextDailySpinTime = nil
                    self.talkCancellable?.cancel()
                } else {
                    self.nextDailySpinTime = self.nextDailySpinTime
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
