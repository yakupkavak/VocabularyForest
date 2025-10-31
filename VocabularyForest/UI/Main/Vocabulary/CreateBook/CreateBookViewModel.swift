//
//  VocabularyMainViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.10.2025.
//

import Foundation
import Combine

class CreateBookViewModel: ObservableObject {
    
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
    @Published var toastMessageModel: CreateBookToastType = .none
    @Published var bookcasesList: [Bookcase] = []
    private var coreDataManager = CoreDataManager.shared
    
    // MARK: - INITALIZE

    init(){
        fetchUserPreferences()
        fetchBookcases()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshBookcase),
            name: .didCreateBookcase,
            object: nil
        )
    }
    
    // MARK: - HELPERS

    private func fetchUserPreferences() {
        guard let lastBookcaseName = UserDefaults.standard.string(
            forKey: BookcaseConstants.bookcase
        )else {
            return
        }
        if let bookcase = coreDataManager.fetchBookcase(name: lastBookcaseName) {
            fetchBookWithCoreData(bookcase: bookcase)
        }
    }
    
    private func fetchBookWithCoreData(bookcase: Bookcase) {
        currentBookcase = bookcase
        learningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.unwrappedLearningLanguage
        })
        meaningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.unwrappedmeaningLanguage
            
        })
    }
    
    func fetchBookWithModel(bookcaseModel: BookcaseModel){
        if let bookcase = coreDataManager.fetchBookcase(name: bookcaseModel.bookcaseName) {
            fetchBookWithCoreData(bookcase: bookcase)
        }
    }
    
    @objc private func refreshBookcase(notification: NSNotification){
        guard let notificationBookcaseName = notification.userInfo?[BookcaseNotificationConstants.createdBookcaseName] as? String else {
            return
        }
        guard let newBookcase = coreDataManager.fetchBookcase(name: notificationBookcaseName) else {
            return
        }
        currentBookcase = newBookcase
        toastMessageModel = .none
        toastMessageModel = .firstBookcaseCreated
        if let newBookcases = coreDataManager.fetchBookcases() {
            if(bookcasesList.isEmpty){
                UserDefaults.standard.set(
                    newBookcases.first?.unwrappedName,forKey: BookcaseConstants.bookcase
                )
            }
            bookcasesList = newBookcases
        }
    }
    
    private func fetchBookcases(){
        bookcasesList = coreDataManager.fetchBookcases() ?? []
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
