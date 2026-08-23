//
//  ForestAudioService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import AVFoundation

protocol AudioServiceProtocol {
    func playBackgroundMusic()
    func stopMusic()
    func startGameMusic()
    func updateVolume(musicLevel: Double, sfxLevel: Double, isMuted: Bool)
    func playSFX(filename: String)
}

class ForestAudioService: NSObject, AudioServiceProtocol {
    
    // MARK: - PROPERTIES
    
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    private var currentMusicVolume: Float = 0.5
    private var currentSFXVolume: Float = 0.8
    private var isMuted: Bool = false
    private let allTracks = [
        "nature-0", "nature-1", "nature-2",
        "nature-3", "nature-4", "nature-5"
    ]
    private var playlist: [String] = []
    private var currentTrackIndex = 0
    private var consecutiveTrackFailures = 0
    private let logger: AppLoggerProtocol = AppLogger.shared
    
    // MARK: - INIT
    
    override init() {
        super.init()
        shufflePlaylist()
    }
    
    // MARK: - PUBLIC CONTROLS
    
    func startGameMusic() {
        
    }
    
    func playBackgroundMusic() {
        stopMusic()
        if let player = musicPlayer, player.isPlaying { return }
        playCurrentTrack()
    }
    
    func stopMusic() {
        musicPlayer?.stop()
    }
    
    func updateVolume(musicLevel: Double, sfxLevel: Double, isMuted: Bool) {
        self.isMuted = isMuted
        self.currentMusicVolume = Float(musicLevel)
        self.currentSFXVolume = Float(sfxLevel)
        
        if isMuted {
            musicPlayer?.volume = 0
            sfxPlayer?.volume = 0
        } else {
            musicPlayer?.volume = currentMusicVolume
            sfxPlayer?.volume = currentSFXVolume
        }
    }
    
    func playSFX(filename: String) {
        if isMuted || currentSFXVolume <= 0 { return }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else { return }
        
        do {
            sfxPlayer = try AVAudioPlayer(contentsOf: url)
            sfxPlayer?.volume = currentSFXVolume
            sfxPlayer?.play()
        } catch {
            logger.error("Sound effect playback failed: \(error.localizedDescription)", category: .forest)
        }
    }
}

// MARK: - PRIVATE HELPERS

private extension ForestAudioService {
    
    func shufflePlaylist() {
        playlist = allTracks.shuffled()
        currentTrackIndex = 0
    }
    
    func playCurrentTrack() {
        if currentTrackIndex >= playlist.count {
            shufflePlaylist()
        }
        
        let trackName = playlist[currentTrackIndex]
        playMusicFile(filename: trackName)
    }
    
    func playNextTrack() {
        currentTrackIndex += 1
        playCurrentTrack()
    }
    
    func playMusicFile(filename: String) {
        // If every track in the playlist fails (missing resource, audio session
        // unavailable), stop instead of recursing through playNextTrack forever —
        // the unbounded recursion crashes with a stack overflow.
        guard consecutiveTrackFailures < playlist.count else {
            consecutiveTrackFailures = 0
            return
        }
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            consecutiveTrackFailures += 1
            playNextTrack()
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.delegate = self
            musicPlayer?.volume = isMuted ? 0 : currentMusicVolume
            musicPlayer?.numberOfLoops = 0
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            consecutiveTrackFailures = 0
        } catch {
            consecutiveTrackFailures += 1
            playNextTrack()
        }
    }
}

// MARK: - DELEGATE

extension ForestAudioService: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            playNextTrack()
        }
    }
}
