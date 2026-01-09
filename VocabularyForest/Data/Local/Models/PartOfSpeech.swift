//
//  PartOfSpeech.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import Foundation
import SwiftUI

let partOfSpeechList: [PartOfSpeech] = [.noun, .verb, .adjective, .adverb, .pronoun, .preposition, .conjunction, .interjection, .determiner]

enum PartOfSpeech: String, CaseIterable, Identifiable {
    case noun
    case verb
    case adjective
    case adverb
    case pronoun
    case preposition
    case conjunction
    case interjection
    case determiner

    var id: String { rawValue }

    var localizedText: String {
        switch self {
        case .noun: return String(localized: "İsim")
        case .verb: return String(localized: "Fiil")
        case .adjective: return String(localized: "Sıfat")
        case .adverb: return String(localized: "Zarf")
        case .pronoun: return String(localized: "Zamir")
        case .preposition: return String(localized: "Edat")
        case .conjunction: return String(localized: "Bağlaç")
        case .interjection: return String(localized: "Ünlem")
        case .determiner: return String(localized: "Belirteç")
        }
    }
    private var backgroundColor: Color {
        switch self {
        case .noun: return .blue
        case .verb: return .red
        case .adjective: return .green
        case .adverb: return .orange
        case .pronoun: return .purple
        case .preposition: return .teal
        case .conjunction: return .indigo
        case .interjection: return .pink
        case .determiner: return .gray
        }
    }
    var pasterColor: Color {
        backgroundColor.opacity(0.8)
    }
}
