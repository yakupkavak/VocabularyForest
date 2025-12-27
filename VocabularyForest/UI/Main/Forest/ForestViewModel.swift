//
//  ForestViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import Foundation
import Combine

protocol ForestViewModelOutputProcotol: AnyObject {
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
    func checkBookCount(battleMode: BattleEnemyModel,
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
    
    init(audioService: AudioServiceProtocol = ForestAudioService()) {
        self.audioService = audioService
        super.init()
        if let bookcases = CoreDataManager.shared.fetchBookcases() {
            bookcaseList = bookcases
        }
    }
}

// MARK:  - HELPERS

extension ForestViewModel: ForestViewModelProtocol {
    
    func closeBookError() {
        showBookThreshold = false
    }
    
    func checkBookCount(battleMode: BattleEnemyModel, gameLevel: GameLevel, bookcaseSelection: GameBookcaseSelection) -> Bool {
        let minBook = calculateMinBookCount(battleMode: battleMode, gameLevel: gameLevel)
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
        return true
    }
    
    func startRain() {
        showRainButton = false
        output?.startRain()
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
        if !forestInitalized {
            let result = coreDataManager.createForestGame(helper: ForestGameHelper())
            if result.status == .success {
                UserDefaults.standard.set(true, forKey: "forestInitalized")
            }
        }
        
        // MARK: - FETCH ANIMAL
        
        let resultAnimal = coreDataManager.fetchAnimals()
        if resultAnimal.status == .success {
            guard let animals = resultAnimal.data else { return }
            for animal in animals {
                if !animalList.contains(where: { $0 == animal}) {
                    animalList.append(animal)
                    output?.setupAnimals(animals: animal)
                }
            }
         }
        
        // MARK: - FETCH SCULPTURE
        
        let sculptureResult = coreDataManager.fetchSculptures()
        if sculptureResult.status == .success {
            guard let sculptures = sculptureResult.data else { return }
            for sculpture in sculptures {
                if !sculptureList.contains(where: { $0 == sculpture}) {
                    sculptureList.append(sculpture)
                    output?.setupSculpture(sculpture: sculpture)
                }
            }
        }
        
        // MARK: - FETCH TREE
        
        let resultTree = coreDataManager.fetchTrees()
        if resultTree.status == .success {
            guard let trees = resultTree.data else { return }
            for tree in trees {
                if !treeList.contains(where: { $0 == tree}) {
                    treeList.append(tree)
                    output?.setupPlant(plant: tree)
                }
            }
         }
        
        // MARK: - FETCH STATUS
        
        let result = coreDataManager.fetchForestStatus()
        switch result.status {
        case .success:
            if let forestData = result.data {
                forestStatus = ForestStatusModel(rainValue: forestData.rainValue, landHealthPercentage: forestData.landHealthPercentage, landStatus: forestData.landStatus, gold: forestData.gold)
                if(forestData.rainValue == 50) {
                    showRainButton = true
                }
            }
        case .loading:
            print("loading")
        case .error:
            print("fetch forest error")
        }
        
        fetchQuests()
    }
    
    private func fetchQuests() {
        dailyQuestList = []
        weeklyQuestList = []
        monthlyQuestList = []
        specialQuestList = []
        let questResult = coreDataManager.fetchQuests()
        if questResult.status == .success, let questList = questResult.data {
            for quest in questList {
                switch quest.type {
                case .daily:
                    dailyQuestList.append(quest)
                case .weekly:
                    weeklyQuestList.append(quest)
                case .monthly:
                    monthlyQuestList.append(quest)
                case .special:
                    specialQuestList.append(quest)
                }
            }
        }
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

