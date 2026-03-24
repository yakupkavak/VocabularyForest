//
//  BookcaseRequest.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation
import YakoSwift

// MARK: - BookcaseRequest

public struct BookcaseRequest: Codable {
    public let id, sourceLanguage, targetLanguage, name: String?
    public let wordCount, version: Int?
    public let updatedAt: String?
    public let words: [Word]?
    
    public init(id: String?, sourceLanguage: String?, targetLanguage: String?, name: String?, wordCount: Int?, version: Int?, updatedAt: String?, words: [Word]?) {
        self.id = id
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.name = name
        self.wordCount = wordCount
        self.version = version
        self.updatedAt = updatedAt
        self.words = words
    }
}

// MARK: - Word

public struct Word: Codable {
    public let id, term, definition, example: String?
    public let description, partOfSpeech, createdAt: String?
    
    public init(id: String?, term: String?, definition: String?, example: String?, description: String?, partOfSpeech: String?, createdAt: String?) {
        self.id = id
        self.term = term
        self.definition = definition
        self.example = example
        self.description = description
        self.partOfSpeech = partOfSpeech
        self.createdAt = createdAt
    }
}
