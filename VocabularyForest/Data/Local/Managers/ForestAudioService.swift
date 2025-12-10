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
    func updateVolume(musicLevel: Double, sfxLevel: Double, isMuted: Bool)
    func playSFX(filename: String)
}

class ForestAudioService: NSObject, AudioServiceProtocol, AVAudioPlayerDelegate {
    
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
    
    override init() {
        super.init()
        shufflePlaylist()
    }
    
    // MARK: - PLAYLIST LOGIC
    
    private func shufflePlaylist() {
        playlist = allTracks.shuffled()
        currentTrackIndex = 0
    }
    
    func playBackgroundMusic() {
        if let player = musicPlayer, player.isPlaying { return }
        playCurrentTrack()
    }
    
    private func playCurrentTrack() {
        if currentTrackIndex >= playlist.count {
            shufflePlaylist()
        }
        
        let trackName = playlist[currentTrackIndex]
        playMusicFile(filename: trackName)
    }
    
    private func playNextTrack() {
        currentTrackIndex += 1
        playCurrentTrack()
    }
    
    // MARK: - CORE AUDIO PLAYER
    
    private func playMusicFile(filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
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
            
        } catch {
            playNextTrack()
        }
    }
    
    // MARK: - DELEGATE
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            playNextTrack()
        }
    }
    
    // MARK: - CONTROLS
    
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
            print("SFX Error: \(error)")
        }
    }
}
