//
//  Language.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import Foundation

struct Language: Identifiable, Hashable {
    let id: String
    let name: String
    
    var localizedName: String {
        let currentLocale = Locale.current
        if self.id.contains("-"),
           currentLocale.language.languageCode?.identifier == "en" {
            return self.name
        }
        if let systemName = currentLocale.localizedString(forIdentifier: self.id) {
            return systemName
        } else {
            return self.name
        }
    }
}

class LanguageData {
    
    static let allLanguages: [Language] = [
        Language(id: "en-US", name: "İngilizce (US)"),
        Language(id: "en-GB", name: "İngilizce (UK)"),
        Language(id: "es", name: "İspanyolca"),
        Language(id: "pt-BR", name: "Portekizce (Brezilya)"),
        Language(id: "zh-CN", name: "Çince (Basitleştirilmiş)"),
        Language(id: "ar", name: "Arapça"),
        Language(id: "hi", name: "Hintçe"),
        Language(id: "ru", name: "Rusça"),
        Language(id: "tr", name: "Türkçe"),
        Language(id: "fr", name: "Fransızca"),
        Language(id: "ja", name: "Japonca"),
        Language(id: "ko", name: "Korece")
    ]
}
