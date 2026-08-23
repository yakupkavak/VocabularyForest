//
//  CreateBookcaseViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import Foundation
import Combine

class CreateBookcaseViewModel: ObservableObject {
    
    // MARK: - DEPENDENCIES

    private let coreDataManager: CoreDataManagerProtocol
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - PROPERTIES
    
    @Published var emptyInitialBookcaseName = false
    @Published var emptyInitialVocabularyLanguage = false
    @Published var emptyInitialMeaningLanguage = false
    @Published var bookcaseName = ""
    @Published var learningLanguage: Language? = nil
    @Published var meaningLanguage: Language? = nil

    // MARK: - INIT

    init(coreDataManager: CoreDataManagerProtocol, analyticsService: AnalyticsServiceProtocol){
        self.coreDataManager = coreDataManager
        self.analyticsService = analyticsService
    }
    
    // MARK: - HELPERS
    
    func createBookcase(bookcaseName: String, learningLanguage: String, meaningLanguage: String){
        if let bookcase = coreDataManager.createBookcase(
            name: bookcaseName,
            learningLanguage: learningLanguage,
            meaningLanguage: meaningLanguage,
            contextType: .main
        ) {
            setBookcaseDefault(bookcase: bookcase)
            let languagePair = "\(learningLanguage)_\(meaningLanguage)"
            analyticsService.log(.bookcaseCreated(languagePair: languagePair, source: .manual))
            analyticsService.set(.learningLanguagePair(languagePair))
        }
    }
    
    func checkAndCreateBookcase() -> Bool{
        var isValid = true
        if(bookcaseName.isEmpty){
            emptyInitialBookcaseName = true
            isValid = false
        }else {
            emptyInitialBookcaseName = false
        }
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
            return true
        }
        return false
    }

}
