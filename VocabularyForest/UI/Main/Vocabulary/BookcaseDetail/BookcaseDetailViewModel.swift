//
//  BookcaseDetailViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.10.2025.
//

import Combine

final class BookcaseDetailViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var books: [Book] = []
    private var bookcase: Bookcase? = nil
    private var dataManager = CoreDataManager.shared
    var bookcaseName: String
    
    // MARK: - INIT
    
    init(bookcaseName: String) {
        self.bookcaseName = bookcaseName
        fetchBookcase(bookcaseName: bookcaseName)
        if let bookcase {
            fetchBooks(bookcase: bookcase)
        }
    }
    
    // MARK: - HELPERS
    
    private func fetchBookcase(bookcaseName: String){
        bookcase = dataManager.fetchBookcase(name: bookcaseName)
    }
    
    func fetchBooks(bookcase: Bookcase){
        books = dataManager.fetchBooks(bookcase: bookcase) ?? []
        print("books -> \(books)")
    }

}
