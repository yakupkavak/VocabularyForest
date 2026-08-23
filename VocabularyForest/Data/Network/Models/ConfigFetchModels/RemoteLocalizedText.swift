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

    public init(
        tr: String? = nil, en: String? = nil, es: String? = nil, fr: String? = nil,
        de: String? = nil, pt: String? = nil, it: String? = nil,
        ru: String? = nil, ar: String? = nil, hi: String? = nil,
        ja: String? = nil, ko: String? = nil, zh: String? = nil
    ) {
        self.tr = tr
        self.en = en
        self.es = es
        self.fr = fr
        self.de = de
        self.pt = pt
        self.it = it
        self.ru = ru
        self.ar = ar
        self.hi = hi
        self.ja = ja
        self.ko = ko
        self.zh = zh
    }

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
        case "it": return it ?? en ?? ""
        default:   return en ?? tr ?? ""
        }
    }
    
    public static func mock(en: String = "test") -> RemoteLocalizedText {
        RemoteLocalizedText(tr: en, en: en, es: en, fr: en, de: en, pt: en, it: en, ru: en, ar: en, hi: en, ja: en, ko: en, zh: en)
    }
}
