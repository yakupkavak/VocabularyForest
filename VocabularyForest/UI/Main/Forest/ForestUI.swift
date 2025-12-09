//
//  ForestUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SwiftUI
import SpriteKit

protocol ForestUIProtocol {
    func showOptions()
    func showQuests()
    func showGameSelection()
}

// MARK: - CONSTANTS

private extension ForestUI {
    enum Constant {
        static let optionsList: [SettingsModel] = [
            SettingsModel<SettingType>(title: "Resume", icon: "forward_button", color: .brown500, type: .resume),
            SettingsModel(title: "Settings", icon: "settings_button", color: .brown500, type: .settings),
            SettingsModel(title: "Home", icon: "exit_button", color: .brown500, type: .home)
        ]
    }
}

// MARK: - VIEW

struct ForestUI: View {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject var router: LearningRouter
    @StateObject private var viewModel = ForestViewModel()
    @State private var forestScene = ForestScene()
    @State private var showOption = false
    @State private var showSetting = false
    @State private var showGameSelect = false
    @AppStorage(AppStorageNames.musicVolume.rawValue) private var musicVolume: Double = 0.5
    @AppStorage(AppStorageNames.sfxVolume.rawValue) private var sfxVolume: Double = 0.8
    @AppStorage(AppStorageNames.isMuted.rawValue) private var isMuted: Bool = false
    @AppStorage(AppStorageNames.isHapticsEnabled.rawValue) private var isHapticsEnabled: Bool = true
    @State private var showQuest = false
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            if showOption {
                options
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(2.0)
            }
            if showSetting {
                settings
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(2.0)
            }
            if showQuest {
                ForestQuestUI(
                    showQuest: $showQuest,
                    dailyQuests: viewModel.dailyQuestList,
                    weeklyQuests: viewModel.weeklyQuestList,
                    monthlyQuests: viewModel.monthlyQuestList,
                    specialQuests: viewModel.specialQuestList
                ) { model in
                    viewModel.claimReward(quest: model)
                }
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(2.0)
            }
            if showGameSelect {
                GameSelectUI(showGameSelect: $showGameSelect) { type, mode, level in
                    showQuest = false
                    router.navigate(to: .game(type, mode, level))
                }
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(2.0)
            }
            SpriteView(scene: gameScene)
                .ignoresSafeArea(.all)
                .navigationBarBackButtonHidden().zIndex(1.0)
        }.task {
            self.viewModel.output = forestScene
            self.forestScene.helper = viewModel
            viewModel.fetchForest()
        }
        .onAppear {
            viewModel.updateAudioSettings(music: musicVolume, sfx: sfxVolume, isMuted: isMuted)
            viewModel.startGameMusic()
        }
        .onChange(of: musicVolume) { newValue in
            viewModel.updateAudioSettings(music: newValue, sfx: sfxVolume, isMuted: isMuted)
        }
        .onChange(of: sfxVolume) { newValue in
            viewModel.updateAudioSettings(music: musicVolume, sfx: newValue, isMuted: isMuted)
        }
        .onChange(of: isMuted) { newValue in
            viewModel.updateAudioSettings(music: musicVolume, sfx: sfxVolume, isMuted: newValue)
        }
    }
}

// MARK: - UI COMPONENTS

private extension ForestUI {
    var gameScene: SKScene {
        forestScene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        forestScene.scaleMode = .fill
        forestScene.helper = viewModel
        forestScene.forestHelper = self
        return forestScene
    }
    var options: some View {
        VStack {
            ZStack {
                Image("title_header").resizable().scaledToFit()
                Text("Options").foregroundStyle(.white).font(.system(size: 24))
            }
            ForEach(Constant.optionsList, id: \.self) { model in
                settingsRow(model: model).onTapGesture {
                    switch model.type {
                    case .resume:
                        showOption = false
                    case .settings:
                        showOption = false
                        showSetting = true
                    case .home:
                        showOption = false
                        exitForest()
                    }
                }
            }
        }.padding().background(.brown.opacity(0.8)).cornerRadius(16).zIndex(3.0).frame(width: UIScreen.main.bounds.width * 0.6)
            .overlay(alignment: .topTrailing) {
                Button {
                    showOption = false
                } label: {
                    Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                        .offset(x: 12, y: -12)
                }
            }
    }
    var settings: some View {
        VStack(spacing: 20) {
            ZStack {
                Image("title_header").resizable().scaledToFit().frame(height: 50)
                Text("Settings").foregroundStyle(.white).font(.system(size: 24, weight: .bold))
            }
            .padding(.bottom, 10)
            
            VStack(spacing: 24) {
                Group {
                    customSliderRow(title: "Music", icon: "music.note", value: $musicVolume)
                        .disabled(isMuted)
                        .opacity(isMuted ? 0.5 : 1.0)
                    customSliderRow(title: "SFX", icon: "speaker.wave.2.fill", value: $sfxVolume)
                        .disabled(isMuted)
                        .opacity(isMuted ? 0.5 : 1.0)
                    customToggleRow(title: "Mute All", icon: "speaker.slash.fill", isOn: $isMuted)
                }
                
                Divider().background(Color.white.opacity(0.5))
                Group {
                    customToggleRow(title: "Haptics", icon: "iphone.radiowaves.left.and.right", isOn: $isHapticsEnabled)
                }
            }
            .padding(.horizontal, 8)
            
        }
        .padding(24)
        .background(Color.brown.opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("brown300"), lineWidth: 4)
        )
        .zIndex(3.0)
        .frame(width: UIScreen.main.bounds.width * 0.7)
        .overlay(alignment: .topTrailing) {
            Button {
                showSetting = false
            } label: {
                Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
            }
        }
    }
}

// MARK: - HELPERS

private extension ForestUI {
    
    func exitForest() {
        viewModel.stopGameMusic()
        router.navigateToRoot()
    }
}

extension ForestUI: ForestUIProtocol {
    
    func showGameSelection() {
        showGameSelect = true
    }
    
    func showQuests() {
        showQuest = true
    }
    
    func hideQuests() {
        showQuest = false
    }
    
    func hideOptions() {
        showOption = false
    }
    func showOptions() {
        showOption = true
    }
}

#Preview {
    ForestUI()
}
