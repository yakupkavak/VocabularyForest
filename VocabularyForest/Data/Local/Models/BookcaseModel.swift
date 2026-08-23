//
//  BookcaseModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import Foundation
import DependencyContainer

struct BookcaseModel: Equatable, Codable, Hashable, Identifiable {
    var id: UUID
    var bookcaseName: String
    var createdDate: Date
    var learningLanguage: String
    var meaningLanguage: String
    let totalBooksCount: Int
    let longMemoryCount: Int
    let shortMemoryCount: Int
}

/*
struct BookcaseStatus {
    var bookList: [BookModel]
    var longMemoryCount: Int
    var shortMemoryCount: Int
    var totalBooksCount: Int
    var longMemoryBooks: [BookModel]
    var shortMemoryBooks: [BookModel]
}*/

// MARK: - EXTENSION PROPERTIES BOOKCASE MODEL

extension BookcaseModel {
    /*
    public var longMemoryBooksCount: Int? {
        coreDataManager.fetchBookcaseProperties(bookcase: self, contextType: .main)?.longMemoryCount
    }
    public var shortMemoryBooksCount: Int? {
        coreDataManager.fetchBookcaseProperties(bookcase: self, contextType: .main)?.shortMemoryCount
    }
    public var totalBooksCount: Int? {
        coreDataManager.fetchBookcaseProperties(bookcase: self, contextType: .main)?.totalBooksCount
    }
     */
    /*public var longMemoryBooks: [BookModel]? {
        coreDataManager.fetchBookcaseProperties(bookcase: self, contextType: .main)?.longMemoryBooks
    }
    public var shortMemoryBooks: [BookModel]? {
        coreDataManager.fetchBookcaseProperties(bookcase: self, contextType: .main)?.shortMemoryBooks
    }
    public var booksArray: [BookModel]? {
        coreDataManager.fetchBookcaseProperties(bookcase: self, contextType: .main)?.bookList
    }*/
}
