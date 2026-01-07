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
        Language(id: "en-US", name: String(localized: "İngilizce (US)")),
        Language(id: "en-GB", name: String(localized: "İngilizce (Birleşik Krallık)")),
        Language(id: "es",    name: String(localized: "İspanyolca")),
        Language(id: "pt-BR", name: String(localized: "Portekizce (Brezilya)")),
        Language(id: "zh-CN", name: String(localized: "Çince (Basitleştirilmiş)")),
        Language(id: "ar",    name: String(localized: "Arapça")),
        Language(id: "hi",    name: String(localized: "Hintçe")),
        Language(id: "ru",    name: String(localized: "Rusça")),
        Language(id: "tr",    name: String(localized: "Türkçe")),
        Language(id: "fr",    name: String(localized: "Fransızca")),
        Language(id: "de",    name: String(localized: "Almanca")),
        Language(id: "ja",    name: String(localized: "Japonca")),
        Language(id: "ko",    name: String(localized: "Korece"))
    ]
}
