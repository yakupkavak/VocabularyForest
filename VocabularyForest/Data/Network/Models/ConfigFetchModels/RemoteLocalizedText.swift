//
//  RemoteLocalizedText.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

import Foundation

struct RemoteLocalizedText: Decodable, Hashable {
    let tr, en, es, fr: String?
    let de, pt: String?
    
    var localized: String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(preferredLanguage.prefix(2)).lowercased()
        switch languageCode {
        case "tr": return tr ?? en ?? ""
        case "es": return es ?? en ?? ""
        case "fr": return fr ?? en ?? ""
        case "de": return de ?? en ?? ""
        case "pt": return pt ?? en ?? ""
        case "en": return en ?? tr ?? ""
        default:   return en ?? tr ?? ""
        }
    }
    
    static func mock(en: String = "test") -> RemoteLocalizedText {
        RemoteLocalizedText(tr: en, en: en, es: en, fr: en, de: en, pt: en)
    }
}
