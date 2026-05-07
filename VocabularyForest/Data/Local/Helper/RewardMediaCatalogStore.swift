//
//  RewardMediaCatalogStore.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.05.2026.
//

import Foundation

struct RewardMediaCatalogEntry: Codable, Equatable {
    let category: String
    let modelKey: String
    let descriptor: RewardMediaDescriptor
}

enum RewardMediaCatalogStore {
    private static let catalogKey = "reward_media_catalog"
    private static let selectedStarterIDKey = "starter_companion.selected_id"
    private static let selectedStarterChosenKey = "starter_companion.has_selected"

    static func save(entries: [RewardMediaCatalogEntry]) {
        var merged = loadCatalog()
        for entry in entries {
            merged[makeCompositeKey(category: entry.category, modelKey: entry.modelKey)] = entry.descriptor
        }
        persistCatalog(merged)
    }

    static func save(
        category: String,
        modelKey: String,
        descriptor: RewardMediaDescriptor
    ) {
        let entry = RewardMediaCatalogEntry(category: category, modelKey: modelKey, descriptor: descriptor)
        save(entries: [entry])
    }

    static func descriptor(category: String, modelKey: String) -> RewardMediaDescriptor? {
        let key = makeCompositeKey(category: category, modelKey: modelKey)
        return loadCatalog()[key]
    }

    static func markStarterSelection(id: String) {
        UserDefaults.standard.set(id, forKey: selectedStarterIDKey)
        UserDefaults.standard.set(true, forKey: selectedStarterChosenKey)
    }

    static func selectedStarterID() -> String? {
        let value = UserDefaults.standard.string(forKey: selectedStarterIDKey)
        return value?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func hasSelectedStarterCompanion() -> Bool {
        UserDefaults.standard.bool(forKey: selectedStarterChosenKey)
    }

    static func localStarterDefaults() -> [StarterCompanionModel] {
        [
            StarterCompanionModel(
                id: "starter-cat-default",
                modelKey: "Cat",
                category: "animal",
                displayName: String(localized: "Cat"),
                previewImageName: "Cat",
                mediaSourceType: .localAsset,
                mediaFileType: .image,
                previewImageURL: nil,
                sourceFieldKey: nil,
                sourceVersion: nil
            ),
            StarterCompanionModel(
                id: "starter-whitecat-default",
                modelKey: "WhiteCat",
                category: "animal",
                displayName: String(localized: "White Cat"),
                previewImageName: "WhiteCat",
                mediaSourceType: .localAsset,
                mediaFileType: .image,
                previewImageURL: nil,
                sourceFieldKey: nil,
                sourceVersion: nil
            ),
            StarterCompanionModel(
                id: "starter-dog-default",
                modelKey: "Dog",
                category: "animal",
                displayName: String(localized: "Dog"),
                previewImageName: "Dog",
                mediaSourceType: .localAsset,
                mediaFileType: .image,
                previewImageURL: nil,
                sourceFieldKey: nil,
                sourceVersion: nil
            )
        ]
    }
}

private extension RewardMediaCatalogStore {
    static func makeCompositeKey(category: String, modelKey: String) -> String {
        "\(category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())::\(modelKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    static func loadCatalog() -> [String: RewardMediaDescriptor] {
        guard let data = UserDefaults.standard.data(forKey: catalogKey),
              let catalog = try? JSONDecoder().decode([String: RewardMediaDescriptor].self, from: data) else {
            return [:]
        }
        return catalog
    }

    static func persistCatalog(_ catalog: [String: RewardMediaDescriptor]) {
        guard let data = try? JSONEncoder().encode(catalog) else { return }
        UserDefaults.standard.set(data, forKey: catalogKey)
    }
}
