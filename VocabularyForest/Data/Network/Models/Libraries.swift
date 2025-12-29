//
//  Libraries.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation

// MARK: - Libraries

struct Libraries: Decodable {
    let version: Int?
    let updatedAt: String?
    let libraries: [Library]?
}

// MARK: - Library

struct Library: Decodable, Identifiable, Hashable {
    let id, sourceLanguage, targetLanguage: String?
    let name: String?
    let wordCount: Int?
    let fileKey, updatedAt: String?
}

extension String {
    func toLanguageDisplayName() -> String {
        let languages: [String: String] = [
            "en-US": "İngilizce (Amerikan)",
            "en-GB": "İngilizce (Birleşik Krallık) ",
            "es":    "İspanyolca",
            "pt-BR": "Portekizce (Brezilya)",
            "zh-CN": "Çince (Basitleştirilmiş)",
            "ar":    "Arapça",
            "hi":    "Hintçe",
            "ru":    "Rusça",
            "tr":    "Türkçe",
            "fr":    "Fransızca",
            "ja":    "Japonca",
            "ko":    "Korece",
            "de": "Almanca"
        ]
        return languages[self] ?? self
    }
}
