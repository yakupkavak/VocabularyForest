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
            "de":    String(localized: "Almanca")
        ]
        return languages[self] ?? self
    }
}
