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
    func fetchDailySpinRewards() async -> Resource<RemoteDailySpinListModel>
    func fetchQuestsConfig() async -> Resource<RemoteQuestListModel>
    func fetchWeeklyRewards() async -> Resource<RemoteWeeklyListModel>
    func fetchAdventureRoadConfig() async -> Resource<RemoteAdventureRoadListModel>
    func fetchGameEconomyConfig() async -> Resource<GameEconomyConfigModel>
    func fetchConfigParameters() async -> Resource<(ConfigParametersList)>
    func saveDailySpinRewards(data: Any?) async -> Resource<Bool>
    func saveQuestsConfig(data: Any?) async -> Resource<Bool>
    func saveWeeklyRewards(data: Any?) async -> Resource<Bool>
    func saveAdventureRoadConfig(data: Any?) async -> Resource<Bool>
    func saveGameEconomyConfig(data: Any?) async -> Resource<Bool>
    func saveConfigParameters(data: Any?) async -> Resource<(Bool)>
}

final class DocumentaryRepository {
    
    // MARK: - CONSTANTS
    
    private enum FileName {
        static let dailySpinRewards = "DailySpinRewards"
        static let questsConfig = "QuestsConfig"
        static let weeklyRewards = "WeeklyRewards"
        static let adventureRoadConfig = "AdventureRoadConfig"
        static let gameEconomyConfig = "GameEconomyConfig"
        static let configParameters = "ConfigParameters"
    }
    
    // MARK: - PROPERTIES
    
    private let fileManager = FileManager.default
    
    // MARK: - INIT
    
    init() {}
}

// MARK: - PRIVATE HELPERS

private extension DocumentaryRepository {
    func getDocumentDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func saveToDisk(data: Any?, fileName: String) throws {
        guard let data = data else {
            throw DocumentaryError.invalidData
        }
        
        let jsonData: Data
        
        if JSONSerialization.isValidJSONObject(data) {
            jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        } else if let stringData = data as? String, let parsedData = stringData.data(using: .utf8) {
            jsonData = parsedData
        } else {
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
    
    func fetchDailySpinRewards() async -> Resource<RemoteDailySpinListModel> {
        do {
            let model = try fetchFromDisk(fileName: FileName.dailySpinRewards, as: RemoteDailySpinListModel.self)
            return .success(model)
        } catch {
            return .error(error: error)
        }
    }
    
    func fetchQuestsConfig() async -> Resource<RemoteQuestListModel> {
        do {
            let model = try fetchFromDisk(fileName: FileName.questsConfig, as: RemoteQuestListModel.self)
            return .success(model)
        } catch {
            return .error(error: error)
        }
    }
    
    func fetchWeeklyRewards() async -> Resource<RemoteWeeklyListModel> {
        do {
            let model = try fetchFromDisk(fileName: FileName.weeklyRewards, as: RemoteWeeklyListModel.self)
            return .success(model)
        } catch {
            return .error(error: error)
        }
    }
    
    func fetchAdventureRoadConfig() async -> Resource<RemoteAdventureRoadListModel> {
        do {
            let model = try fetchFromDisk(fileName: FileName.adventureRoadConfig, as: RemoteAdventureRoadListModel.self)
            return .success(model)
        } catch {
            return .error(error: error)
        }
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
    
    func saveDailySpinRewards(data: Any?) async -> Resource<Bool> {
        do {
            try saveToDisk(data: data, fileName: FileName.dailySpinRewards)
            return .success(true)
        } catch {
            return .error(error: error)
        }
    }
    
    func saveQuestsConfig(data: Any?) async -> Resource<Bool> {
        do {
            try saveToDisk(data: data, fileName: FileName.questsConfig)
            return .success(true)
        } catch {
            return .error(error: error)
        }
    }
    
    func saveWeeklyRewards(data: Any?) async -> Resource<Bool> {
        do {
            try saveToDisk(data: data, fileName: FileName.weeklyRewards)
            return .success(true)
        } catch {
            return .error(error: error)
        }
    }
    
    func saveAdventureRoadConfig(data: Any?) async -> Resource<Bool> {
        do {
            try saveToDisk(data: data, fileName: FileName.adventureRoadConfig)
            return .success(true)
        } catch {
            return .error(error: error)
        }
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
