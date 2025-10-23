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
    @Published var showInitalize = true
    @Published var currentBookcase: Bookcase? = nil
    @Published var learningLanguage: Language? = nil
    @Published var meaningLanguage: Language? = nil
    @Published var emptyInitialBookcase = false
    @Published var emptyInitialVocabularyLanguage = false
    @Published var emptyInitialMeaningLanguage = false
    @Published var bookcaseName = ""
    @Published var bookLearningWord = ""
    @Published var bookMeaningWord = ""
    @Published var bookExampleSentence = ""
    @Published var bookDescription = ""
    @Published var emptyBookLearningWord = false
    @Published var emptyBookMeaningWord = false
    private var coreDataManager = CoreDataManager.shared
    
    // MARK: - INITALIZE

    init(){
        fetchUserPreferences()
    }
    
    // MARK: - HELPERS

    private func fetchUserPreferences() {
        guard let lastBookcaseName = UserDefaults.standard.string(
            forKey: UserDefaultConstants.bookcase
        )else {
            showInitalize = true
            return
        }
        if let bookcase = coreDataManager.fetchBookcase(name: lastBookcaseName) {
            updateBookcase(bookcase: bookcase)
        }
    }
    
    func createBookcase(bookcaseName: String, learningLanguage: String, meaningLanguage: String) {
        let bookcase = coreDataManager.createBookcase(
            name: bookcaseName,
            learningLanguage: learningLanguage,
            meaningLanguage: meaningLanguage
        )
        UserDefaults.standard.setValue(bookcase.unwrappedName, forKey: UserDefaultConstants.bookcase)
        updateBookcase(bookcase: bookcase)
    }
    
    func checkAndCreateBookcase(){
        var isValid = true
        if(learningLanguage == nil){
            emptyInitialVocabularyLanguage = true
            isValid = false
        }else {
            emptyInitialVocabularyLanguage = false
        }
        if(meaningLanguage == nil){
            emptyInitialMeaningLanguage = true
            isValid = false
        }else {
            emptyInitialMeaningLanguage = false
        }
        if(isValid) {
            createBookcase(bookcaseName: bookcaseName, learningLanguage: learningLanguage!.id, meaningLanguage: meaningLanguage!.id)
        }
    }
    
    private func updateBookcase(bookcase: Bookcase) {
        currentBookcase = bookcase
        learningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.unwrappedLearningLanguage
        })
        meaningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.unwrappedmeaningLanguage
            
        })
        showInitalize = false
    }
    
    func checkAndCreateBook() {
        var isValid = true
        if(bookLearningWord.isEmpty) {
            isValid = false
            emptyBookLearningWord = true
        }else {
            emptyBookLearningWord = false
        }
        if(bookMeaningWord.isEmpty) {
            isValid = false
            emptyBookMeaningWord = true
        }else {
            emptyBookMeaningWord = false
        }
        if isValid {
            createBook()
        }
    }
    
    private func createBook(){
        guard let currentBookcase else {
            return
        }
        coreDataManager.createBook(learningWord: bookLearningWord, meaningWord: bookMeaningWord, exampleSentence: bookExampleSentence, descriptionWord: bookDescription, in: currentBookcase)
    }
}

private extension VocabularyMainViewModel {
    
    enum UserDefaultConstants {
        static let bookcase = "Bookcase"
        static let learningLanguage = "LearningLanguage"
        static let meaningLanguage = "MeaningLanguage"
    }
}
