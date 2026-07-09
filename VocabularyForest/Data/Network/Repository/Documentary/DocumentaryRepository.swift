//
//  DocumentaryRepository.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.05.2026.
//

import Foundation

// MARK: - Error Handling

enum DocumentaryError: Error {
    case invalidData
    case fileNotFound
    case decodingFailed
    case encodingFailed
}

protocol DocumentaryRepositoryProtocol {
    func fetchChestConfig() async throws -> RemoteChestConfigResponse
    func fetchDailySpinModels() async throws -> RemoteDailySpinListModel
    func fetchQuestsConfig() async throws -> RemoteQuestListModel
    func fetchWeeklyRewards() async throws -> RemoteWeeklyListModel
    func fetchAdventureRoadConfig() async throws -> RemoteAdventureRoadListModel
    func fetchGameEconomyConfig() async -> Resource<GameEconomyConfigModel>
    func fetchConfigParameters() async -> Resource<(ConfigParametersList)>
    func saveChestConfig(data: Any?) async throws
    func saveDailySpinRewards(data: Any?) async throws
    func saveQuestsConfig(data: Any?) async throws
    func saveWeeklyRewards(data: Any?) async throws
    func saveAdventureRoadConfig(data: Any?) async throws
    func saveGameEconomyConfig(data: Any?) async -> Resource<Bool>
    func saveConfigParameters(data: Any?) async -> Resource<(Bool)>
}

final class DocumentaryRepository {
    
    // MARK: - CONSTANTS
    
    private enum FileName {
        static let chestConfig = "ChestConfig"
        static let dailySpinRewards = "DailySpinRewards"
        static let questsConfig = "QuestsConfig"
        static let weeklyRewards = "WeeklyRewards"
        static let adventureRoadConfig = "AdventureRoadConfig"
        static let gameEconomyConfig = "GameEconomyConfig"
        static let configParameters = "ConfigParameters"
    }
    
    // MARK: - PROPERTIES
    
    private let fileManager = FileManager.default
    private let baseDirectoryURL: URL
    
    // MARK: - INIT
    
    init(directoryURL: URL? = nil) {
        if let directoryURL = directoryURL {
            self.baseDirectoryURL = directoryURL
        } else {
            self.baseDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
    }
}

// MARK: - PRIVATE HELPERS

private extension DocumentaryRepository {
    func getDocumentDirectory() -> URL {
        return baseDirectoryURL
    }
    
    func saveToDisk(data: Any?, fileName: String) throws {
        guard let data = data else {
            throw DocumentaryError.invalidData
        }
        
        let jsonData: Data
        
        if JSONSerialization.isValidJSONObject(data) {
            jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        }else if let stringData = data as? String, let parsedData = stringData.data(using: .utf8) {
            jsonData = parsedData
        }else if let rawData = data as? Data {
            jsonData = rawData
        }else {
            throw DocumentaryError.encodingFailed
        }
        
        let fileURL = getDocumentDirectory().appendingPathComponent("\(fileName).json")
        try jsonData.write(to: fileURL, options: .atomic)
    }
    
    func fetchFromDisk<T: Decodable>(fileName: String, as type: T.Type) throws -> T {
        let fileURL = getDocumentDirectory().appendingPathComponent("\(fileName).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw DocumentaryError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - DocumentaryRepositoryProtocol

extension DocumentaryRepository: DocumentaryRepositoryProtocol {
    
    // MARK: - FETCH METHODS
    
    func fetchChestConfig() async throws -> RemoteChestConfigResponse {
        try fetchFromDisk(fileName: FileName.chestConfig, as: RemoteChestConfigResponse.self)
    }

    func fetchDailySpinModels() async throws -> RemoteDailySpinListModel {
        try fetchFromDisk(fileName: FileName.dailySpinRewards, as: RemoteDailySpinListModel.self)
    }
    
    func fetchQuestsConfig() async throws -> RemoteQuestListModel {
        try fetchFromDisk(fileName: FileName.questsConfig, as: RemoteQuestListModel.self)
    }
    
    func fetchWeeklyRewards() async throws -> RemoteWeeklyListModel {
        try fetchFromDisk(fileName: FileName.weeklyRewards, as: RemoteWeeklyListModel.self)
    }
    
    func fetchAdventureRoadConfig() async throws -> RemoteAdventureRoadListModel {
        try fetchFromDisk(fileName: FileName.adventureRoadConfig, as: RemoteAdventureRoadListModel.self)
    }
    
    func fetchGameEconomyConfig() async -> Resource<GameEconomyConfigModel> {
        do {
            let model = try fetchFromDisk(fileName: FileName.gameEconomyConfig, as: GameEconomyConfigModel.self)
            return .success(model)
        } catch {
            return .error(error: error)
        }
    }
    
    func fetchConfigParameters() async -> Resource<ConfigParametersList> {
        do {
            let model = try fetchFromDisk(fileName: FileName.configParameters, as: ConfigParametersList.self)
            return .success(model)
        } catch {
            return .error(error: error)
        }
    }
    
    // MARK: - SAVE METHODS
    
    func saveChestConfig(data: Any?) async throws {
        try saveToDisk(data: data, fileName: FileName.chestConfig)
    }
    
    func saveDailySpinRewards(data: Any?) async throws {
        try saveToDisk(data: data, fileName: FileName.dailySpinRewards)
    }
    
    func saveQuestsConfig(data: Any?) async throws {
        try saveToDisk(data: data, fileName: FileName.questsConfig)
    }
    
    func saveWeeklyRewards(data: Any?) async throws {
        try saveToDisk(data: data, fileName: FileName.weeklyRewards)
    }
    
    func saveAdventureRoadConfig(data: Any?) async throws {
        try saveToDisk(data: data, fileName: FileName.adventureRoadConfig)
    }
    
    func saveGameEconomyConfig(data: Any?) async -> Resource<Bool> {
        do {
            try saveToDisk(data: data, fileName: FileName.gameEconomyConfig)
            return .success(true)
        } catch {
            return .error(error: error)
        }
    }
    
    func saveConfigParameters(data: Any?) async -> Resource<Bool> {
        do {
            try saveToDisk(data: data, fileName: FileName.configParameters)
            return .success(true)
        } catch {
            return .error(error: error)
        }
    }
}
