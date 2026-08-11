//
//  MockAudioService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.03.2026.
//

import Foundation
@testable import VocabularyForest

final class MockAudioService: AudioServiceProtocol {
    
    // MARK: - ÇAĞRI KONTROLLERİ (Hangi fonksiyonlar tetiklendi?)
    var isPlayBackgroundMusicCalled = false
    var isStopMusicCalled = false
    var isStartGameMusicCalled = false
    var isUpdateVolumeCalled = false
    var isPlaySFXCalled = false
    var playSFXCallCount = 0
    
    // MARK: - YAKALANAN DEĞERLER (İçeriye hangi parametreler geldi?)
    var capturedMusicLevel: Double = 0
    var capturedSFXLevel: Double = 0
    var capturedIsMuted: Bool = false
    var capturedSFXFilename: String?
    
    // MARK: - PROTOCOL IMPLEMENTATION
    
    func playBackgroundMusic() {
        isPlayBackgroundMusicCalled = true
    }
    
    func stopMusic() {
        isStopMusicCalled = true
    }
    
    func startGameMusic() {
        isStartGameMusicCalled = true
    }
    
    func updateVolume(musicLevel: Double, sfxLevel: Double, isMuted: Bool) {
        isUpdateVolumeCalled = true
        capturedMusicLevel = musicLevel
        capturedSFXLevel = sfxLevel
        capturedIsMuted = isMuted
    }
    
    func playSFX(filename: String) {
        isPlaySFXCalled = true
        playSFXCallCount += 1
        capturedSFXFilename = filename
    }
    
    // MARK: - TEST YARDIMCISI (Opsiyonel)
    /// Birden fazla testi aynı sınıfta koşarken değerleri sıfırlamak için kullanılır.
    func reset() {
        isPlayBackgroundMusicCalled = false
        isStopMusicCalled = false
        isStartGameMusicCalled = false
        isUpdateVolumeCalled = false
        isPlaySFXCalled = false
        playSFXCallCount = 0
        capturedMusicLevel = 0
        capturedSFXLevel = 0
        capturedIsMuted = false
        capturedSFXFilename = nil
    }
}
