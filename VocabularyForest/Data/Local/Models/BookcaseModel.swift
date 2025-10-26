//
//  BookcaseModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import Foundation

struct BookcaseModel: Equatable {
    var bookcaseName: String
    var createdDate: Date
    var learningLanguage: String
    var meaningLanguage: String
    var books: [BookModel]
}

