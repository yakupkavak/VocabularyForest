//
//  BookModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import Foundation

struct BookModel: Equatable, Codable, Hashable {
    var bookName: String
    var createdDate: Date
    var learningWord: String
    var meaningWord: String
    var exampleSentence: String?
    var descriptionWord: String?
    var partOfSpeech: String?
    var bookcase: BookcaseModel
}
