//
//  ForestDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import CoreData

class ForestDataManager {
    
    // MARK: - PROPERTIES
    
    static let shared = ForestDataManager()
    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "VocabularyForest")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Core data couldn't inin -> \(error.localizedDescription)")
            }
        }
        viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - HELPERS
    
    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Core data couldn't saved -> \(error.localizedDescription)")
        }
    }
    
    func createForest(helper: ForestGameHelperProtocol) {
        let quests = helper.initalizeQuests()
    }
    
    func fetchForestStatus() -> ForestStatusModel {
        ForestStatusModel(rainPercentage: 1, landHealthPercentage: 1, landStatus: false)
    }
    
    func updateForestStatus(model: ForestStatusModel) {
        
    }
}
