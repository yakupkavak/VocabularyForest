//
//  BookcaseFeedViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import Combine

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
}
