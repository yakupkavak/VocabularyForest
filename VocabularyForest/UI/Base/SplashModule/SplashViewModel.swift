//
//  SplashViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import Foundation

class SplashViewModel: BaseViewModel {
    
    private let forestController: ForestControllerServiceProtocol
    
    init(forestController: ForestControllerServiceProtocol) {
        self.forestController = forestController
        super.init()
        setupApplication()
    }
    
    private func setupApplication() {
        Task(priority: .background) {
            await forestController.initializeNewGame()
        }
    }
    
}
