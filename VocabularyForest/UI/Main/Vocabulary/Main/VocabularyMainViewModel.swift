//
//  VocabularyMainViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.10.2025.
//

import Foundation
import Combine

class VocabularyMainViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var updateUI: UserPreferences? = nil
    @Published var showInitalize: Bool? = false

    // MARK: - INITALIZE

    init(){
        fetchUserPreferences()
    }
    
    private func fetchUserPreferences() {
        guard let bookcase = UserDefaults.standard.string(
            forKey: UserDefaultConstants.bookcase
        )else {
            showInitalize = true
            return
        }
        guard let learningLanguage = UserDefaults.standard.string(
            forKey: UserDefaultConstants.learningLanguage
        )else {
            showInitalize = true
            return
        }
        guard let meaningLanguage = UserDefaults.standard.string(
            forKey: UserDefaultConstants.meaningLanguage
        )else {
            showInitalize = true
            return
        }
        updateUI = UserPreferences(
            bookcase: bookcase,
            learningLanguage: learningLanguage,
            meaningLanguage: meaningLanguage
        )
    }
}

private extension VocabularyMainViewModel {
    
    enum UserDefaultConstants {
        static let bookcase = "Bookcase"
        static let learningLanguage = "LearningLanguage"
        static let meaningLanguage = "MeaningLanguage"
    }
}
