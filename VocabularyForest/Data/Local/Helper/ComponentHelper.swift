//
//  ComponentHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.02.2026.
//

import Foundation

func generateRandomName(type: ComponentType) -> String {
    switch type {
    case .animal:
        return ["Boncuk", String(localized: "Mutlu"), String(localized: "Huzur")].randomElement() ?? String("Mutlu")
    case .plant:
        return [String(localized: "Güneş"), String(localized: "Ay"), String(localized: "Venüs")].randomElement() ?? String("Mars")
    case .sculpture:
        return [String(localized: "Bilge"), String(localized: "Zafer"), String(localized: "umut")].randomElement() ?? String("Sonsuzluk")
    }
}
