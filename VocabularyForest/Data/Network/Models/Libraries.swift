//
//  Libraries.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation

// MARK: - Libraries

struct Libraries: Codable {
    let version: Int?
    let updatedAt: String?
    let libraries: [Library]?
}

// MARK: - Library

struct Library: Codable {
    let id, sourceLanguage, targetLanguage, level: String?
    let wordCount: Int?
    let fileKey, updatedAt: String?
}
