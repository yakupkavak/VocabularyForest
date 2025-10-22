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
        if let systemName = currentLocale.localizedString(forIdentifier: self.id) {
            return systemName
        } else {
            return self.name
        }
    }
}

class LanguageData {
    
    static let allLanguages: [Language] = [
        Language(id: "en-US", name: "English (US)"),
        Language(id: "en-GB", name: "English (UK)"),
        Language(id: "tr", name: "Turkish"),
        Language(id: "es", name: "Spanish"),
        Language(id: "fr", name: "French"),
        Language(id: "de", name: "German"),
        Language(id: "ja", name: "Japanese"),
        Language(id: "it", name: "Italian"),
        Language(id: "pt-PT", name: "Portuguese (Portugal)"),
        Language(id: "pt-BR", name: "Portuguese (Brazil)"),
        Language(id: "ru", name: "Russian"),
        Language(id: "zh-CN", name: "Chinese (Simplified)"),
        Language(id: "zh-TW", name: "Chinese (Traditional)"),
        Language(id: "ar", name: "Arabic"),
        Language(id: "hi", name: "Hindi"),
        Language(id: "ko", name: "Korean"),
        Language(id: "nl", name: "Dutch"),
        Language(id: "sv", name: "Swedish"),
        Language(id: "no", name: "Norwegian"),
        Language(id: "da", name: "Danish"),
        Language(id: "fi", name: "Finnish"),
        Language(id: "el", name: "Greek"),
        Language(id: "pl", name: "Polish"),
        Language(id: "cs", name: "Czech"),
        Language(id: "hu", name: "Hungarian"),
        Language(id: "ro", name: "Romanian"),
        Language(id: "uk", name: "Ukrainian"),
        Language(id: "bg", name: "Bulgarian"),
        Language(id: "hr", name: "Croatian"),
        Language(id: "sr", name: "Serbian"),
        Language(id: "sk", name: "Slovak"),
        Language(id: "sl", name: "Slovenian"),
        Language(id: "et", name: "Estonian"),
        Language(id: "lv", name: "Latvian"),
        Language(id: "lt", name: "Lithuanian"),
        Language(id: "he", name: "Hebrew"),
        Language(id: "id", name: "Indonesian"),
        Language(id: "ms", name: "Malay"),
        Language(id: "th", name: "Thai"),
        Language(id: "vi", name: "Vietnamese"),
        Language(id: "fa", name: "Persian"),
        Language(id: "ur", name: "Urdu"),
        Language(id: "bn", name: "Bengali"),
        Language(id: "pa", name: "Punjabi"),
        Language(id: "gu", name: "Gujarati"),
        Language(id: "ta", name: "Tamil"),
        Language(id: "te", name: "Telugu"),
        Language(id: "mr", name: "Marathi"),
        Language(id: "af", name: "Afrikaans"),
        Language(id: "sw", name: "Swahili")
    ]
}
