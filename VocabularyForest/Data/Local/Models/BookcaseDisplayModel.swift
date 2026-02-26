//
//  BookcaseDisplayModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.11.2025.
//

import CoreData

struct BookcaseDisplayItem: Identifiable, Hashable {
    
    // MARK: - PROPERTIES
    
    let id: UUID
    let bookcase: BookcaseModel
    let animalModel: AnimalBodyModel
    
    // MARK: - EQUATABLE HELPERS

    static func == (birinci: BookcaseDisplayItem, ikinci: BookcaseDisplayItem) -> Bool {
        birinci.id == ikinci.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
