//
//  CreateBookcaseViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import Foundation
import Combine

class CreateBookcaseViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var emptyInitialBookcaseName = false
    @Published var emptyInitialVocabularyLanguage = false
    @Published var emptyInitialMeaningLanguage = false
    @Published var bookcaseName = ""
    @Published var learningLanguage: Language? = nil
    @Published var meaningLanguage: Language? = nil
    private var coreDataManager = CoreDataManager.shared

    // MARK: - INIT

    init(){
        
    }
    
    // MARK: - HELPERS
    
    func createBookcase(bookcaseName: String, learningLanguage: String, meaningLanguage: String){
        let bookcase = coreDataManager.createBookcase(
            name: bookcaseName,
            learningLanguage: learningLanguage,
            meaningLanguage: meaningLanguage
        )
        let userInfo: [String: Any] = [
                BookcaseNotificationConstants.createdBookcaseName: bookcaseName,
                BookcaseNotificationConstants.createdBookcaseLearning: learningLanguage,
                BookcaseNotificationConstants.createdBookcaseMeaning: meaningLanguage
            ]
        UserDefaults.standard.setValue(bookcase.unwrappedName, forKey: BookcaseConstants.bookcase)
        UserDefaults.standard.setValue(bookcase.unwrappedLearningLanguage, forKey: BookcaseConstants.learningLanguage)
        UserDefaults.standard.setValue(bookcase.unwrappedmeaningLanguage, forKey: BookcaseConstants.meaningLanguage)
        NotificationCenter.default.post(name: .didCreateBookcase, object: nil, userInfo: userInfo)
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
