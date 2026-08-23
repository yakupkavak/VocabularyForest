//
//  ComponentModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.01.2026.
//

import Foundation

protocol ComponentNameable {
    var id: UUID { get }
    var characterName: String { get set }
}

extension ComponentNameable {
    // Default names are persisted as catalog keys; localizing at display time keeps
    // them in sync with the device language. Custom user names are not catalog keys,
    // so the lookup falls through and returns them unchanged.
    var localizedCharacterName: String {
        String(localized: String.LocalizationValue(characterName))
    }
}

enum ComponentType {
    case animal, plant, sculpture
}
