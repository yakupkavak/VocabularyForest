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
    func setupAnimals(animals: [AnimalModel]?)
}

protocol ForestViewModelProtocol: AnyObject {
    func startGameMusic()
    func stopGameMusic()
    func updateAudioSettings(music: Double, sfx: Double, isMuted: Bool)
    func playSoundEffect(name: String)
    func didTapTree(id: UUID)
    func didCollectWater(amount: Int)
    func fetchForest()
}

class ForestViewModel: BaseViewModel {
    
    // MARK: - PROPERTIES
    
    @Published var dailyQuestList: [QuestModel] = []
    @Published var weeklyQuestList: [QuestModel] = []
    @Published var monthlyQuestList: [QuestModel] = []
    @Published var specialQuestList: [QuestModel] = []
    let coreDataManager = ForestDataManager.shared
    private let audioService: AudioServiceProtocol
    weak var output: ForestViewModelOutputProcotol?
    
    init(audioService: AudioServiceProtocol = ForestAudioService()) {
        self.audioService = audioService
        super.init()
    }
}

extension ForestViewModel: ForestViewModelProtocol {
    
    // MARK:  - HELPERS

    func fetchForest() {
        //coreDataManager.fetchForestStatus()
        //coreDataManager.fetchTrees()
        //coreDataManager.fetchQuests()
        //coreDataManager.fetchSculptures()
        /*
        coreDataManager.createForestGame(helper: ForestGameHelper())
        coreDataManager.createAnimal(animal: AnimalModel(name: "Cat", assetName: "Cat", createdDate: Date(), healthValue: 10, isAlive: true, xPosition: 10, yPosition: 10))
            */
        let forestInitalized = UserDefaults.standard.bool(forKey: "forestInitalized")
        if !forestInitalized {
            let result = coreDataManager.createForestGame(helper: ForestGameHelper())
            if result.status == .success {
                UserDefaults.standard.set(true, forKey: "forestInitalized")
            }
        }
        let resultAnimal = coreDataManager.fetchAnimals()
        if resultAnimal.status == .success {
            guard let animals = resultAnimal.data else { return }
            output?.setupAnimals(animals: animals)
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
    func getTrees() -> Resource<[Tree]> {
        coreDataManager.fetchTrees()
    }
    
    func getSculptures() -> Resource<[Sculpture]> {
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

