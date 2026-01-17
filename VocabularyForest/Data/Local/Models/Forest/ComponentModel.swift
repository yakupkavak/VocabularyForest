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

enum ComponentType {
    case animal, plant, sculpture
}
