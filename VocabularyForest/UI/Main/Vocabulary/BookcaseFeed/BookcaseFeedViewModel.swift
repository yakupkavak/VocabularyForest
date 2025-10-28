//
//  BookcaseFeedViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import Combine
import Foundation

class BookcaseFeedViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var bookcases: [Bookcase] = []
    private var manager = CoreDataManager.shared
    
    // MARK: - INIT
    
    init() {
        fetchBookcases()
    }
    
    // MARK: HELPERS
    
    func fetchBookcases(){
        bookcases = manager.fetchBookcases() ?? []
    }
    
    func deleteBookcase(indexSet: IndexSet){
        let bookcasesToDelete = indexSet.map { bookcases[$0] }
        for deleteBookcase in bookcasesToDelete {
            manager.deleteBookcase(bookcase: deleteBookcase)
        }
    }
}
