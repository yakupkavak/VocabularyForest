//
//  RemoteLocalizedText.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

import Foundation

public struct RemoteLocalizedText: Decodable, Hashable {
    public let tr, en, es, fr: String?
    public let de, pt, it: String?
    public let ru, ar, hi: String?
    public let ja, ko, zh: String?

    public var localized: String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(preferredLanguage.prefix(2)).lowercased()
        switch languageCode {
        case "tr": return tr ?? en ?? ""
        case "es": return es ?? en ?? ""
        case "fr": return fr ?? en ?? ""
        case "de": return de ?? en ?? ""
        case "pt": return pt ?? en ?? ""
        case "en": return en ?? tr ?? ""
        case "ru": return ru ?? en ?? ""
        case "ar": return ar ?? en ?? ""
        case "hi": return hi ?? en ?? ""
        case "ja": return ja ?? en ?? ""
        case "ko": return ko ?? en ?? ""
        case "zh": return zh ?? en ?? ""
        default:   return en ?? tr ?? ""
        }
    }
    
    public static func mock(en: String = "test") -> RemoteLocalizedText {
        RemoteLocalizedText(tr: en, en: en, es: en, fr: en, de: en, pt: en, it: en, ru: en, ar: en, hi: en, ja: en, ko: en, zh: en)
    }
}
