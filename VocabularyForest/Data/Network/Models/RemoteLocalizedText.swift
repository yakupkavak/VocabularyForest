//
//  RemoteLocalizedText.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

import Foundation

struct RemoteLocalizedText: Codable, Equatable {
    let variants: [String: String]

    init(variants: [String: String]) {
        self.variants = variants
    }

    init(from decoder: Decoder) throws {
        let singleValue = try decoder.singleValueContainer()

        if let rawString = try? singleValue.decode(String.self) {
            let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
            self.variants = trimmed.isEmpty ? [:] : ["default": trimmed]
            return
        }

        if let rawMap = try? singleValue.decode([String: String].self) {
            var normalized: [String: String] = [:]
            for (key, value) in rawMap {
                let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedValue.isEmpty else { continue }
                normalized[key] = trimmedValue
            }
            self.variants = normalized
            return
        }

        self.variants = [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(variants)
    }

    func resolved(locale: Locale = .current) -> String? {
        guard !variants.isEmpty else { return nil }

        let normalizedMap = variants.reduce(into: [String: String]()) { partial, item in
            let key = item.key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "_", with: "-")
            guard !key.isEmpty else { return }
            partial[key] = item.value
        }

        let localeIdentifier = locale.identifier.lowercased().replacingOccurrences(of: "_", with: "-")
        let languageCode = locale.language.languageCode?.identifier.lowercased()

        if let exactMatch = normalizedMap[localeIdentifier] {
            return exactMatch
        }

        if let languageCode, let languageMatch = normalizedMap[languageCode] {
            return languageMatch
        }

        if let primaryLanguage = localeIdentifier.split(separator: "-").first.map(String.init),
           let primaryMatch = normalizedMap[primaryLanguage] {
            return primaryMatch
        }

        if let english = normalizedMap["en"] {
            return english
        }

        if let turkish = normalizedMap["tr"] {
            return turkish
        }

        if let fallback = normalizedMap["default"] {
            return fallback
        }

        return normalizedMap.values.first
    }
}
