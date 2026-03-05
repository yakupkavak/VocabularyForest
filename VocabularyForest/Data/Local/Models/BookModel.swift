//
//  BookModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import Foundation

struct BookModel: Equatable, Codable, Hashable, Identifiable {
    var id: UUID
    var bookcaseId: UUID
    var createdDate: Date
    var learningWord: String
    var meaningWord: String
    var exampleSentence: String?
    var descriptionWord: String?
    var longMemory: Bool
    var shortMemory: Bool
    var partOfSpeech: PartOfSpeech
}

struct BookHelperModel {
    var learningcode: String
    var meaningCode: String
    var bookcaseName: String
}

extension BookModel {
    public var bookcaseName: String? {
        CoreDataManager.shared.fetchBookHelperProperties(book: self, contextType: .main)?.bookcaseName
    }
    public var learningLanguageCode: String? {
        CoreDataManager.shared.fetchBookHelperProperties(book: self, contextType: .main)?.learningcode
    }
    public var meaningLanguageCode: String? {
        CoreDataManager.shared.fetchBookHelperProperties(book: self, contextType: .main)?.meaningCode
    }
}
