//
//  StarterCompanionSelectionViewModel.swift
//  VocabularyForest
//
//  Created by Codex on 3.05.2026.
//

import Foundation
import DependencyContainer
import Combine

final class StarterCompanionSelectionViewModel: ObservableObject {
    @Published private(set) var options: [StarterCompanionModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var selectedStarterID: String?
    @Published private(set) var didCompleteSelection = false
    @Published var errorMessage: String?

    private let remoteConfigRepository: RemoteConfigRepositoryProtocol
    private let forestDataManager: ForestDataManagerProtocol
    private let forestEntityService: ForestEntityServiceProtocol

    init(
        remoteConfigRepository: RemoteConfigRepositoryProtocol = DC.shared.resolve(type: .singleInstance, for: RemoteConfigRepositoryProtocol.self),
        forestDataManager: ForestDataManagerProtocol = DC.shared.resolve(type: .singleInstance, for: ForestDataManagerProtocol.self),
        forestEntityService: ForestEntityServiceProtocol = DC.shared.resolve(type: .singleInstance, for: ForestEntityServiceProtocol.self)
    ) {
        self.remoteConfigRepository = remoteConfigRepository
        self.forestDataManager = forestDataManager
        self.forestEntityService = forestEntityService
        self.selectedStarterID = RewardMediaCatalogStore.selectedStarterID()
    }

    func loadOptionsIfNeeded() {
        guard options.isEmpty, !isLoading else { return }
        isLoading = true

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            let result = await remoteConfigRepository.fetchStarterCompanionsConfig()
            let loadedOptions = (result.status == .success ? result.data : nil) ?? RewardMediaCatalogStore.localStarterDefaults()

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.options = loadedOptions.filter { !$0.modelKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                self.isLoading = false
            }
        }
    }

    func selectStarter(_ option: StarterCompanionModel) {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        Task(priority: .background) { [weak self] in
            guard let self else { return }

            // Keep source mapping deterministic even if remote config is unavailable later.
            RewardMediaCatalogStore.save(
                category: option.category,
                modelKey: option.modelKey,
                descriptor: RewardMediaDescriptor(
                    sourceType: option.mediaSourceType,
                    fileType: option.mediaFileType,
                    previewImageURL: option.previewImageURL,
                    sourceFieldKey: option.sourceFieldKey,
                    sourceVersion: option.sourceVersion
                )
            )

            let created = createStarterInForestIfNeeded(option)

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.isSaving = false

                guard created else {
                    self.errorMessage = String(localized: "Starter companion could not be added.")
                    return
                }

                RewardMediaCatalogStore.markStarterSelection(id: option.id)
                self.selectedStarterID = option.id
                self.didCompleteSelection = true
            }
        }
    }
}

private extension StarterCompanionSelectionViewModel {
    func createStarterInForestIfNeeded(_ option: StarterCompanionModel) -> Bool {
        let modelKey = option.modelKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !modelKey.isEmpty else {
            return false
        }

        switch normalizedCategory(option.category) {
        case "animal":
            let existingAnimals = forestEntityService.fetchAnimals(contextType: .background).data ?? []
            if existingAnimals.contains(where: { $0.assetName.caseInsensitiveCompare(modelKey) == .orderedSame }) {
                return true
            }
            let result = forestDataManager.claimReward(model: .animal(modelName: modelKey), contextType: .background)
            return result.status == .success

        case "plant":
            let existingPlants = forestEntityService.fetchTrees(contextType: .background).data ?? []
            if existingPlants.contains(where: { $0.assetName.caseInsensitiveCompare(modelKey) == .orderedSame }) {
                return true
            }
            let result = forestDataManager.claimReward(model: .plant(modelName: modelKey), contextType: .background)
            return result.status == .success

        case "sculpture":
            let existingSculptures = forestEntityService.fetchSculptures(contextType: .background).data ?? []
            if existingSculptures.contains(where: { $0.assetName.caseInsensitiveCompare(modelKey) == .orderedSame }) {
                return true
            }
            let result = forestDataManager.claimReward(model: .sculpture(modelName: modelKey), contextType: .background)
            return result.status == .success

        default:
            return false
        }
    }

    func normalizedCategory(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
