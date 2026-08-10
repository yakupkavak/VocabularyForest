//
//  Libraries.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation

// MARK: - Libraries

public struct Libraries: Decodable {
    public let version: Int?
    public let updatedAt: String?
    public let libraries: [Library]?
    
    public init(version: Int?, updatedAt: String?, libraries: [Library]?) {
        self.version = version
        self.updatedAt = updatedAt
        self.libraries = libraries
    }
}

// MARK: - Library

public struct Library: Decodable, Identifiable, Hashable {
    public let id, sourceLanguage, targetLanguage: String?
    public let name: String?
    public let wordCount: Int?
    public let fileKey, updatedAt: String?
    
    public init(id: String?, sourceLanguage: String?, targetLanguage: String?, name: String?, wordCount: Int?, fileKey: String?, updatedAt: String?) {
        self.id = id
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.name = name
        self.wordCount = wordCount
        self.fileKey = fileKey
        self.updatedAt = updatedAt
    }
}

public extension String {
    func toLanguageDisplayName() -> String {
        let languages: [String: String] = [
            "en-US": String(localized: "İngilizce (Amerikan)"),
            "en-GB": String(localized: "İngilizce (Birleşik Krallık) "),
            "es":    String(localized: "İspanyolca"),
            "pt-BR": String(localized: "Portekizce (Brezilya)"),
            "zh-CN": String(localized: "Çince (Basitleştirilmiş)"),
            "ar":    String(localized: "Arapça"),
            "hi":    String(localized: "Hintçe"),
            "ru":    String(localized: "Rusça"),
            "tr":    String(localized: "Türkçe"),
            "fr":    String(localized: "Fransızca"),
            "ja":    String(localized: "Japonca"),
            "ko":    String(localized: "Korece"),
            "de":    String(localized: "Almanca"),
            "it":    String(localized: "İtalyanca"),
        ]
        return languages[self] ?? self
    }
}
