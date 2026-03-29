//
//  MockForestData.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.03.2026.
//

import Foundation
import CoreData
@testable import VocabularyForest

final class MockForestDataManager: ForestDataManagerProtocol {
    
    // MARK: - KONTROL EDİLEBİLİR DÖNÜŞ DEĞERLERİ (STUBS)
    // Testlerde "Veritabanından şu gelmiş gibi yap" demek için bunları değiştireceğiz
    var mockBoolResult: Resource<Bool> = .success(true)
    var mockForestStatusResult: Resource<ForestStatusModel> = .error(error: ForestError.emptyForest)
    var mockQuestsResult: Resource<[QuestModel]> = .success([])
    var mockAnimalsResult: Resource<[AnimalModel]> = .success([])
    var mockTreesResult: Resource<[TreeModel]> = .success([])
    var mockSculpturesResult: Resource<[SculptureModel]> = .success([])
    
    var mockSingleAnimal: AnimalModel? = nil
    var mockSingleTree: TreeModel? = nil
    var mockSingleSculpture: SculptureModel? = nil
    var mockCurrentForest: Forest? = nil
    
    // MARK: - ÇAĞRI KONTROLLERİ (Hangi fonksiyon çalıştı?)
    var isCheckGameCalled = false
    var isStartRainCalled = false
    var isCreateForestGameCalled = false
    var isFetchForestStatusCalled = false
    
    // MARK: - YAKALANAN DEĞERLER (İçeriye hangi veri yollandı?)
    var capturedAnimal: AnimalModel?
    var capturedTree: TreeModel?
    var capturedSculpture: SculptureModel?
    var capturedQuestToClaim: QuestModel?
    var capturedComponentName: String?
    var capturedRainValue: Int?
    var capturedMoneyValue: Int?
    var capturedDiamondValue: Int?
    
    // MARK: - UPDATE QUESTS & GAME STATE
    
    func checkAndResetTimeBasedQuests(helper: ForestGameHelperProtocol, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        return mockBoolResult
    }
    
    func checkGame(contextType: ForestDataManager.ContextType) {
        isCheckGameCalled = true
    }
    
    func checkAndUpdateRain(contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        return mockBoolResult
    }
    
    // MARK: - CREATE HELPERS
    
    func createForestGame(helper: ForestGameHelperProtocol, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        isCreateForestGameCalled = true
        return mockBoolResult
    }
    
    func createTree(tree model: TreeModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedTree = model
        return mockBoolResult
    }
    
    func createAnimal(animal model: AnimalModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedAnimal = model
        return mockBoolResult
    }
    
    func createSculpture(sculpture model: SculptureModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedSculpture = model
        return mockBoolResult
    }
    
    // MARK: - FETCH HELPERS
    
    func fetchSculpture(id: UUID, contextType: ForestDataManager.ContextType) -> SculptureModel? {
        return mockSingleSculpture
    }
    
    func fetchAnimal(id: UUID, contextType: ForestDataManager.ContextType) -> AnimalModel? {
        return mockSingleAnimal
    }
    
    func fetchPlant(id: UUID, contextType: ForestDataManager.ContextType) -> TreeModel? {
        return mockSingleTree
    }
    
    func getCurrentForest(context: NSManagedObjectContext) -> Forest? {
        return mockCurrentForest
    }
    
    func fetchForestStatus(contextType: ForestDataManager.ContextType) -> Resource<ForestStatusModel> {
        isFetchForestStatusCalled = true
        return mockForestStatusResult
    }
    
    func fetchQuests(contextType: ForestDataManager.ContextType) -> Resource<[QuestModel]> {
        return mockQuestsResult
    }
    
    func fetchAnimals(contextType: ForestDataManager.ContextType) -> Resource<[AnimalModel]> {
        return mockAnimalsResult
    }
    
    func fetchTrees(contextType: ForestDataManager.ContextType) -> Resource<[TreeModel]> {
        return mockTreesResult
    }
    
    func fetchSculptures(contextType: ForestDataManager.ContextType) -> Resource<[SculptureModel]> {
        return mockSculpturesResult
    }
    
    // MARK: - UPDATE HELPERS
    
    func claimReward(quest: QuestModel, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedQuestToClaim = quest
        return mockBoolResult
    }
    
    func winGame(gameLevel: GameLevel, battleEnemyMode: BattleEnemyModel, gameType: BattleQuestionType, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        return mockBoolResult
    }
    
    func correctAnswer(questionType: BattleQuestionType, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        return mockBoolResult
    }
    
    func updateComponentPosition(model: ComponentModelProtocol, xValue: CGFloat, yValue: CGFloat, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        return mockBoolResult
    }
    
    func updateComponentName(id: UUID, type: ComponentType, newName: String, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedComponentName = newName
        return mockBoolResult
    }
    
    func updateRainValue(rain: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedRainValue = rain
        return mockBoolResult
    }
    
    func startRain(contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        isStartRainCalled = true
        return mockBoolResult
    }
    
    func updateMoneyValue(money: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedMoneyValue = money
        return mockBoolResult
    }
    
    func updateDiamondValue(diamond: Int, contextType: ForestDataManager.ContextType) -> Resource<Bool> {
        capturedDiamondValue = diamond
        return mockBoolResult
    }
    
    // MARK: - RESET (Opsiyonel Test Yardımcısı)
    func reset() {
        mockBoolResult = .success(true)
        mockForestStatusResult = .error(error: ForestError.emptyForest)
        isCheckGameCalled = false
        isStartRainCalled = false
        capturedAnimal = nil
        capturedTree = nil
        capturedSculpture = nil
        capturedComponentName = nil
        capturedRainValue = nil
        capturedMoneyValue = nil
        capturedDiamondValue = nil
    }
}
