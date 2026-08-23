//
//  ComponentHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.02.2026.
//

import Foundation

func generateRandomName(type: ComponentType) -> String {
    switch type {
    // Default names are stored as raw catalog keys so they can be re-localized
    // at display time when the device language changes (see localizedCharacterName).
    case .animal:
        return ["Boncuk", "Mutlu", "Huzur"].randomElement() ?? String("Mutlu")
    case .plant:
        return ["Güneş", "Ay", "Venüs"].randomElement() ?? String("Mars")
    case .sculpture:
        return ["Bilge", "Zafer", "umut"].randomElement() ?? String("Sonsuzluk")
    }
}
