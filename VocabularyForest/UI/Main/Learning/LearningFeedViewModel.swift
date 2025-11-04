//
//  LearningFeedViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.11.2025.
//

import Combine

class LearningFeedViewModel: ObservableObject{
    
    // MARK: - PROPERTIES
    
    @Published var todaysLearningWord = ""
    @Published var todaysMeaning = ""
    @Published var todaysExample = ""
    @Published var todaysDescription = ""
    var dataManager = CoreDataManager.shared

    // MARK: - INIT

    init() {
        fetchData()
    }
    
    // MARK: - HELPERS
    
    private func fetchData() {
        
    }
    
}
