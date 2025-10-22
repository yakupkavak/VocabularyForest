//
//  PartOfSpeech.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import Foundation

enum PartOfSpeech: String {
    case noun
    case verb
    case adjective
    case adverb
    case pronoun
    case preposition
    case conjunction
    case interjection
    case determiner
    
    var localizedText: String {
        switch self {
        case .noun:
            return "Noun"
        case .verb:
            return "Verb"
        case .adjective:
            return "Adjective"
        case .adverb:
            return "Adverb"
        case .pronoun:
            return "Pronoun"
        case .preposition:
            return "Preposition"
        case .conjunction:
            return "Conjuction"
        case .interjection:
            return "Interjection"
        case .determiner:
            return "Determiner"
        }
    }
}
