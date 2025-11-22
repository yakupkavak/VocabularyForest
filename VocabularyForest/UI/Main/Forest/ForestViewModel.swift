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
    weak var output: ForestViewModelOutputProcotol?
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

