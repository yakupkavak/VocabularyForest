//
//  EditBookViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//

import Foundation
import Combine

class EditBookViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var currentBookcase: Bookcase? = nil
    @Published var learningLanguage: Language? = nil
    @Published var meaningLanguage: Language? = nil
    @Published var bookLearningWord = ""
    @Published var bookMeaningWord = ""
    @Published var bookExampleSentence = ""
    @Published var bookDescription = ""
    @Published var emptyBookLearningWord = false
    @Published var emptyBookMeaningWord = false
    @Published var toastMessageModel: EditBookToastType = .none
    private var coreDataManager = CoreDataManager.shared
    
    // MARK: - INITALIZE

    init(){
        fetchUserPreferences()
        fetchBookcases()
    }
    
    // MARK: - HELPERS

    private func fetchUserPreferences() {
        guard let lastBookcaseName = UserDefaults.standard.string(
            forKey: BookcaseConstants.bookcase
        )else {
            return
        }
        if let bookcase = coreDataManager.fetchBookcase(name: lastBookcaseName) {
            updateCurrentBookcase(bookcase: bookcase)
        }else {
            UserDefaults.standard.set(nil, forKey: BookcaseConstants.bookcase)
        }
    }
    
    func fetchBookWithModel(bookcaseModel: BookcaseModel){
        if let bookcase = coreDataManager.fetchBookcase(name: bookcaseModel.bookcaseName) {
            updateCurrentBookcase(bookcase: bookcase)
        }
    }
    
    private func updateCurrentBookcase(bookcase: Bookcase){
        currentBookcase = bookcase
        learningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.unwrappedLearningLanguage
        })
        meaningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.unwrappedmeaningLanguage
        })
    }
    
    func fetchBookcases(){
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
        let book = coreDataManager.createBook(learningWord: bookLearningWord, meaningWord: bookMeaningWord, exampleSentence: bookExampleSentence, descriptionWord: bookDescription, in: currentBookcase)
        bookLearningWord = ""
        bookMeaningWord = ""
        bookExampleSentence = ""
        bookDescription = ""

        toastMessageModel = .newBookCreated

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.toastMessageModel == .newBookCreated {
                self.toastMessageModel = .none
            }
        }
    }
}
