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
    func showForestInfo()
}

// MARK: - CONSTANTS

private extension ForestUI {
    enum Constant {
        static let optionsList: [SettingsModel] = [
            SettingsModel<SettingType>(title: String(localized: "Resume"), icon: "forward_button", color: .brown500, type: .resume),
            SettingsModel(title: String(localized: "Settings"), icon: "settings_button", color: .brown500, type: .settings),
            SettingsModel(title: String(localized: "Orman Bilgileri"), icon: "FAQ", color: .brown500, type: .info),
            SettingsModel(title: String(localized: "Home"), icon: "exit_button", color: .brown500, type: .home)
        ]
    }
}

// MARK: - VIEW

struct ForestUI: View {
    
    // MARK: - PROPERTIES
    
    @Binding var tabBar: BaseTabTypes
    @ObservedObject var bookcaseRouter: BookcaseRouter
    @EnvironmentObject var router: LearningRouter
    @StateObject private var viewModel = ForestViewModel()
    @State private var forestScene = ForestScene()
    @State private var showOption = false
    @State private var showSetting = false
    @State private var showGameSelect = false
    @State private var showQuest = false
    @State private var showForest = false
    @State private var selectedQuestForGame: QuestModel? = nil
    @AppStorage(AppStorageNames.musicVolume.rawValue) private var musicVolume: Double = 0.5
    @AppStorage(AppStorageNames.sfxVolume.rawValue) private var sfxVolume: Double = 0.8
    @AppStorage(AppStorageNames.isMuted.rawValue) private var isMuted: Bool = false
    @AppStorage(AppStorageNames.isHapticsEnabled.rawValue) private var isHapticsEnabled: Bool = true
    @AppStorage(AppStorageNames.shownForestInfo.rawValue) private var forestSeen: Bool = false
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            if !forestSeen {
                GameInfoUI(showForestPopUp: Binding(
                    get: {
                        return !forestSeen
                    },
                    set: { newValue in
                        if newValue == false {
                            forestSeen = true
                        }
                    }
                ))
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }
            if showOption {
                options.zIndex(4.0)
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }
            if showSetting {
                settings.zIndex(4.0)
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }
            if showQuest {
                ForestQuestUI(
                    showQuest: $showQuest,
                    selectQuest: { model in
                        selectedQuestForGame = model
                        showQuest = false
                        showGameSelect = true
                    },
                    dailyQuests: viewModel.dailyQuestList,
                    weeklyQuests: viewModel.weeklyQuestList,
                    monthlyQuests: viewModel.monthlyQuestList,
                    specialQuests: viewModel.specialQuestList
                ) { model in
                    viewModel.claimReward(quest: model)
                }.zIndex(4.0)
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }
            if showGameSelect {
                gameSelect.zIndex(4.0).frame(maxHeight: UIScreen.main.bounds.height * 0.75)
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }
            if showForest {
                ForestInfoUI(forestModel: viewModel.forestStatus) {
                    showForest = false
                }.zIndex(4.0)
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }
            if viewModel.showRainButton {
                VStack{
                    Spacer()
                    Button {
                        viewModel.startRain()
                    } label: {
                        Text("Start Rain").modifier(TitleBackground())
                    }.padding(.bottom, 32)
                }.zIndex(4.0)
            }
            if viewModel.showBookThreshold {
                ForestPopUp(titleText: String(localized: "Eksik soru"), descriptionText: String(localized: "Kitaplığında bu oyun için yeterli sayıda kelimele bulunmuyor. Hazır kütüphane indirerek hızlıca oynayabilirsin"), onConfirm: {
                    tabBar = .bookcases
                    bookcaseRouter.navigate(to: .bookcasePacket)
                    exitForest()
                }, onDenied: {viewModel.closeBookError()}, confirmText: String(localized: "Kütüphane"), deniedText: String(localized: "Orman"), showForestPopUp: $viewModel.showBookThreshold)
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
    var gameSelect: some View {
        GameSelectUI(
            initialQuest: selectedQuestForGame,
            showGameSelect: $showGameSelect,
            bookcaseList: viewModel.bookcaseList,
            startGame: { type, mode, level, questionSelection in
                if (viewModel.checkBookCount(type: type, battleMode: mode, gameLevel: level, bookcaseSelection: questionSelection)) {
                    selectedQuestForGame = nil
                    showGameSelect = false
                    switch questionSelection {
                    case .allBookcases:
                        router.navigate(to: .game(type, mode, level, nil))
                    case .spesific(let model):
                        router.navigate(to: .game(type, mode, level, model))
                    }
                }
            }
        )
        .zIndex(4.0)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
    }
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
                    case .info:
                        forestSeen = false
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
    
    func openQuestGame(model: QuestModel) {
        showQuest = false
        showGameSelect = true
    }
    
    func exitForest() {
        viewModel.stopGameMusic()
        router.navigateToRoot()
    }
}

extension ForestUI: ForestUIProtocol {
    
    func showForestInfo() {
        showForest = true
    }
    
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
    @State var tabbar = BaseTabTypes.bookcases
    var router = BookcaseRouter()
    ForestUI(tabBar: $tabbar, bookcaseRouter: router)
}
