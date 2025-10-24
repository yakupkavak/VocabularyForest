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
    @Published var createdBookcase: Bookcase? = nil
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
        UserDefaults.standard.setValue(bookcase.unwrappedName, forKey: BookcaseConstants.bookcase)
        NotificationCenter.default.post(name: .didCreateBookcase, object: nil)
        createdBookcase = bookcase
    }
    
    func checkAndCreateBookcase(){
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
        }
    }

}
