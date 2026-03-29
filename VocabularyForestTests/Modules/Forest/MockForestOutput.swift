//
//  MockForestOutput.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.03.2026.
//

import Foundation
@testable import VocabularyForest

// MARK: - MOCK FOREST OUTPUT (SAHTE EKRAN / SCENE)
final class MockForestOutput: ForestViewModelOutputProcotol {
    
    // MARK: - ÇAĞRI KONTROLLERİ (Hangi fonksiyonlar, kaç kere çağrıldı?)
    var isStartFadeCalled = false
    var isStartDroughtCalled = false
    var isStartRainCalled = false
    var isStopRainCalled = false
    
    var setupAnimalCallCount = 0
    var setupSculptureCallCount = 0
    var setupPlantCallCount = 0
    var talkComponentCallCount = 0
    
    // MARK: - YAKALANAN DEĞERLER (ViewModel ekrana ne çizdirmek istedi?)
    // Ekrana birden fazla hayvan/ağaç eklenebileceği için bunları Dizi (Array) olarak tutuyoruz
    var capturedAnimals: [AnimalModel?] = []
    var capturedSculptures: [SculptureModel] = []
    var capturedPlants: [TreeModel] = []
    
    // Konuşma balonu için son yakalanan veriler
    var capturedTalkModel: ComponentType?
    var capturedTalkID: UUID?
    var capturedTalkMessage: String?
    
    // MARK: - PROTOKOL FONKSİYONLARI (Ajanın görevleri)
    
    func startFade() {
        isStartFadeCalled = true
    }
    
    func startDrought() {
        isStartDroughtCalled = true
    }
    
    func startRain() {
        isStartRainCalled = true
    }
    
    func stopRain() {
        isStopRainCalled = true
    }
    
    func setupAnimal(animal: AnimalModel?) {
        setupAnimalCallCount += 1
        capturedAnimals.append(animal)
    }
    
    func setupSculpture(sculpture: SculptureModel) {
        setupSculptureCallCount += 1
        capturedSculptures.append(sculpture)
    }
    
    func setupPlant(plant: TreeModel) {
        setupPlantCallCount += 1
        capturedPlants.append(plant)
    }
    
    func talkComponent(type model: ComponentType, id: UUID, message: String) {
        talkComponentCallCount += 1
        capturedTalkModel = model
        capturedTalkID = id
        capturedTalkMessage = message
    }
    
    // MARK: - RESET (Testleri Temizleme)
    func reset() {
        isStartFadeCalled = false
        isStartDroughtCalled = false
        isStartRainCalled = false
        isStopRainCalled = false
        
        setupAnimalCallCount = 0
        setupSculptureCallCount = 0
        setupPlantCallCount = 0
        talkComponentCallCount = 0
        
        capturedAnimals.removeAll()
        capturedSculptures.removeAll()
        capturedPlants.removeAll()
        
        capturedTalkModel = nil
        capturedTalkID = nil
        capturedTalkMessage = nil
    }
}
