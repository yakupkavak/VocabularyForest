//
//  DocumentRepositoryTest.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.06.2026.
//

@testable import VocabularyForest
import Testing
import Foundation

@Suite("Document Repository Tests")
struct DocumentRepositoryTest {
    
    var sut: DocumentaryRepositoryProtocol
    var tempTestDirectory: URL
    
    init() {
        self.tempTestDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempTestDirectory, withIntermediateDirectories: true)
        self.sut = DocumentaryRepository(directoryURL: tempTestDirectory)
    }
    
    @MainActor
    @Test func canSaveDocument() async throws {
        let questJson = try TestBundleHelper.fetchMockJSON(filename: "mock_quests_config")
        let questModels = try TestBundleHelper.loadMockJSON(filename: "mock_quests_config", model: RemoteQuestListModel.self)
        print(questJson)
        try await sut.saveQuestsConfig(data: questJson)
        let fetchQuestJson = try await sut.fetchQuestsConfig()
        #expect(questModels.id == fetchQuestJson.id, "Quest ids are not equal")
        #expect(questModels.items?.count == fetchQuestJson.items?.count, "Quest counts are not equal")
    }
}
