//
//  ForestViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import Foundation
import Combine

protocol ForestViewModelOutputProcotol: AnyObject {
    func startFade()
    func startDrought()
    func startRain()
    func stopRain()
    func setupAnimals(animals: AnimalModel?)
    func setupSculpture(sculpture: SculptureModel)
    func setupPlant(plant: TreeModel)
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
}

class ForestViewModel: BaseViewModel {
    
    // MARK: - PROPERTIES
    
    @Published var dailyQuestList: [QuestModel] = []
    @Published var weeklyQuestList: [QuestModel] = []
    @Published var monthlyQuestList: [QuestModel] = []
    @Published var specialQuestList: [QuestModel] = []
    @Published var bookcaseList: [Bookcase] = []
    @Published var forestStatus: ForestStatusModel? = nil
    @Published var showRainButton = false
    @Published var showBookThreshold = false
    private var animalList: [AnimalModel] = []
    private var sculptureList: [SculptureModel] = []
    private var treeList: [TreeModel] = []
    let coreDataManager = ForestDataManager.shared
    private let audioService: AudioServiceProtocol
    weak var output: ForestViewModelOutputProcotol?
    
    init(audioService: AudioServiceProtocol = ForestAudioService.shared) {
        self.audioService = audioService
        super.init()
    }
}

// MARK:  - HELPERS

extension ForestViewModel: ForestViewModelProtocol {
    
    func closeBookError() {
        showBookThreshold = false
    }
    
    func checkBookCount(type: BattleQuestionType, battleMode: BattleEnemyModel, gameLevel: GameLevel, bookcaseSelection: GameBookcaseSelection) -> Bool {
        let minBook = calculateMinBookCount(battleMode: battleMode, gameLevel: gameLevel)
        if type == .learning {
            switch bookcaseSelection {
            case .allBookcases:
                guard let books = CoreDataManager.shared.fetchAllBooksWithExampleDescription() else {
                    showBookThreshold = true
                    return false }
                if books.count < minBook {
                    showBookThreshold = true
                    return false
                }
            case .spesific(let bookcase):
                guard let books = CoreDataManager.shared.fetchBooksExampleDescription(model: bookcase) else {
                    showBookThreshold = true
                    return false }
                if books.count < minBook {
                    showBookThreshold = true
                    return false
                }
            }
        }
        else {
            switch bookcaseSelection {
            case .allBookcases:
                guard let books = CoreDataManager.shared.fetchAllBooks() else {
                    showBookThreshold = true
                    return false }
                if books.count < minBook {
                    showBookThreshold = true
                    return false
                }
            case .spesific(let bookcase):
                guard let books = CoreDataManager.shared.fetchBooks(model: bookcase) else {
                    showBookThreshold = true
                    return false }
                if books.count < minBook {
                    showBookThreshold = true
                    return false
                }
            }
        }
        return true
    }
    
    func startRain() {
        showRainButton = false
        output?.startRain()
        coreDataManager.updateRainValue(rain: -50)
        var time = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            time += 1
            if time == 40 {
                output?.stopRain()
            }
        }
    }
    
    func claimReward(quest: QuestModel) {
        let result = coreDataManager.claimReward(quest: quest)
        if result.status == .success {
            fetchForest()
        }
    }
    
    func fetchForest() {
        let forestInitalized = UserDefaults.standard.bool(forKey: "forestInitalized")

        Task {

            if !forestInitalized {
                let result = coreDataManager.createForestGame(helper: ForestGameHelper())
                if result.status == .success {
                    UserDefaults.standard.set(true, forKey: "forestInitalized")
                }
            }
            
            let fetchedAnimals = coreDataManager.fetchAnimals().data ?? []
            let fetchedSculptures = coreDataManager.fetchSculptures().data ?? []
            let fetchedTrees = coreDataManager.fetchTrees().data ?? []
            let fetchedBookcases = CoreDataManager.shared.fetchBookcases()
            let statusResult = coreDataManager.fetchForestStatus()
            let questResult = coreDataManager.fetchQuests()

            let newAnimals = fetchedAnimals.filter { newItem in
                !self.animalList.contains(where: { $0 == newItem })
            }
            
            let newSculptures = fetchedSculptures.filter { newItem in
                !self.sculptureList.contains(where: { $0 == newItem })
            }
            
            let newTrees = fetchedTrees.filter { newItem in
                !self.treeList.contains(where: { $0 == newItem })
            }
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                if let cases = fetchedBookcases {
                    self.bookcaseList = cases
                }

                

                if !newAnimals.isEmpty { self.animalList.append(contentsOf: newAnimals) }
                if !newSculptures.isEmpty { self.sculptureList.append(contentsOf: newSculptures) }
                if !newTrees.isEmpty { self.treeList.append(contentsOf: newTrees) }

                for animal in newAnimals {
                    self.output?.setupAnimals(animals: animal)
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
            }
        }
    }

    private func processQuests(quests: [QuestModel]) {
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

// MARK: GAME SCENE PROTOCOL

extension ForestViewModel: ForectSceneProtocol {
    
    func getTrees() -> Resource<[TreeModel]> {
        coreDataManager.fetchTrees()
    }
    
    func getSculptures() -> Resource<[SculptureModel]> {
        coreDataManager.fetchSculptures()
    }
    
    func getQuests() -> Resource<[QuestModel]> {
        coreDataManager.fetchQuests()
    }
    
    func treeOnClick(id: UUID) {
        print("")
    }
    
    func getForestStatus() -> Resource<ForestStatusModel> {
        coreDataManager.fetchForestStatus()
    }
    
    func updateForestStatus(model: ForestStatusModel) {
        coreDataManager.updateForestStatus(model: model)
    }
}

