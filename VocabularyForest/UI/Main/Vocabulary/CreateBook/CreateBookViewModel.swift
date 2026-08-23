//
//  VocabularyMainViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.10.2025.
//

import Foundation
import Combine

class CreateBookViewModel: ObservableObject {
    
    // MARK: - DEPENDENCIES

    private let coreDataManager: CoreDataManagerProtocol
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - PROPERTIES
    
    @Published var currentBookcase: BookcaseModel? = nil
    @Published var learningLanguage: Language? = nil
    @Published var meaningLanguage: Language? = nil
    @Published var bookLearningWord = ""
    @Published var bookMeaningWord = ""
    @Published var bookExampleSentence = ""
    @Published var bookDescription = ""
    @Published var partOfSpeech: PartOfSpeech = .noun
    @Published var emptyBookLearningWord = false
    @Published var emptyBookMeaningWord = false
    @Published var toastMessageModel: CreateBookToastType = .none
    @Published var bookcasesList: [BookcaseModel] = []
    
    // MARK: - INITALIZE

    init(coreDataManager: CoreDataManagerProtocol, analyticsService: AnalyticsServiceProtocol){
        self.coreDataManager = coreDataManager
        self.analyticsService = analyticsService
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
        ), let lastBookcaseLearning = UserDefaults.standard.string(
            forKey: BookcaseConstants.learningLanguage
        ), let lastBookcaseMeaning = UserDefaults.standard.string(
            forKey: BookcaseConstants.meaningLanguage
        ) else {
            return
        }
        if let bookcase = coreDataManager.fetchBookcase(
            name: lastBookcaseName,
            learningLanguageCode: lastBookcaseLearning,
            meaningLanguageCode: lastBookcaseMeaning,
            contextType: .background
        ) {
            updateCurrentBookcase(bookcase: bookcase)
        }else {
            UserDefaults.standard.set(nil, forKey: BookcaseConstants.bookcase)
        }
    }
    
    func fetchBookWithModel(bookcaseModel: BookcaseModel){
        if let bookcase = coreDataManager.fetchBookcase(
            name: bookcaseModel.bookcaseName,
            learningLanguageCode: bookcaseModel.learningLanguage,
            meaningLanguageCode: bookcaseModel.meaningLanguage,
            contextType: .main
        ) {
            updateCurrentBookcase(bookcase: bookcase)
        }
    }
    
    @objc private func refreshBookcase(notification: NSNotification){
        guard let notificationBookcaseName = notification.userInfo?[BookcaseNotificationConstants.createdBookcaseName] as? String,
        let notificationBookcaseLearning = notification.userInfo?[BookcaseNotificationConstants.createdBookcaseLearning] as? String,
        let notificationBookcaseMeaning = notification.userInfo?[BookcaseNotificationConstants.createdBookcaseMeaning] as? String
        else {
            return
        }
        guard let newBookcase = coreDataManager.fetchBookcase(
            name: notificationBookcaseName,
            learningLanguageCode: notificationBookcaseLearning,
            meaningLanguageCode: notificationBookcaseMeaning,
            contextType: .background
        ) else {
            return
        }
        updateCurrentBookcase(bookcase: newBookcase)
        toastMessageModel = .none
        toastMessageModel = .firstBookcaseCreated
        if let newBookcases = coreDataManager.fetchSafeBookcases(
            sortDescriptors: nil,
            contextType: .background
        ) {
            if(bookcasesList.isEmpty){
                UserDefaults.standard.set(
                    newBookcases.first?.bookcaseName,forKey: BookcaseConstants.bookcase
                )
            }
            bookcasesList = newBookcases
        }
    }
    
    private func updateCurrentBookcase(bookcase: BookcaseModel){
        currentBookcase = bookcase
        learningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.learningLanguage
        })
        meaningLanguage = LanguageData.allLanguages.first(where: {(language: Language) in
            return language.id == bookcase.meaningLanguage
        })
    }
    
    func fetchBookcases(){
        bookcasesList = coreDataManager.fetchSafeBookcases(
            sortDescriptors: nil,
            contextType: .main
        ) ?? []
    }
    
    func selectTag(model: PartOfSpeech) {
        partOfSpeech = model
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
        if coreDataManager.createSafeBook(
            learningWord: bookLearningWord,
            meaningWord: bookMeaningWord,
            exampleSentence: bookExampleSentence,
            descriptionWord: bookDescription,
            partOfSpeech: partOfSpeech.rawValue,
            safeBookcase: currentBookcase,
            contextType: .main
        ) != nil {
            analyticsService.log(.bookCreated(
                bookcaseID: currentBookcase.id.uuidString,
                hasExample: !bookExampleSentence.isEmpty
            ))
        }else {
            // TODO: Show error
        }
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
