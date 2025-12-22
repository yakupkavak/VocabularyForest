//
//  BookcaseRequest.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation

// MARK: - BookcaseRequest

struct BookcaseRequest: Codable {
    let id, sourceLanguage, targetLanguage, level: String?
    let wordCount, version: Int?
    let updatedAt: String?
    let words: [Word]?
}

// MARK: - Word

struct Word: Codable {
    let id, term, definition, example: String?
    let description, partOfSpeech, createdAt: String?
}
