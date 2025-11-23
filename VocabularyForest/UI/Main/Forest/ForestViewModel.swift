//
//  ForestViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import Foundation

protocol ForestViewModelOutputProcotol: AnyObject {
    func startRain()
    func stopRain()
}

class ForestViewModel: BaseViewModel {
    
    // MARK: - PROPERTIES
    
    let coreDataManager = ForestDataManager.shared
    private let audioService: AudioServiceProtocol
    weak var output: ForestViewModelOutputProcotol?
    
    init(audioService: AudioServiceProtocol = ForestAudioService()) {
        self.audioService = audioService
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

extension ForestViewModel: GameSceneProtocol {
    func getTrees() -> Resource<[Tree]> {
        coreDataManager.fetchTrees()
    }
    
    func getAnimals() -> Resource<[Animal]> {
        coreDataManager.fetchAnimals()
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

