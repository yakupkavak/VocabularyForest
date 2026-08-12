//
//  ForestUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SwiftUI
import SpriteKit
import DependencyContainer

protocol ForestUIProtocol {
    func showOptions()
    func showAnnouncement()
    func showGameSelection()
    func showForestInfo()
    func showMarket()
    func updateComponentName(model: ComponentNameable, type: ComponentType)
}

// MARK: - CONSTANTS

private extension ForestUI {
    enum Constant {
        static let optionsList: [SettingsModel] = [
            SettingsModel<SettingType>(title: String(localized: "Resume"), icon: "right_icon", color: .brown500, type: .resume),
            SettingsModel(title: String(localized: "Settings"), icon: "settings_button", color: .brown500, type: .settings),
            SettingsModel(title: String(localized: "Orman Bilgileri"), icon: "FAQ", color: .brown500, type: .info),
            SettingsModel(title: String(localized: "Orman bileşenleri"), icon: "forest_button", color: .brown500, type: .components),
            SettingsModel(title: String(localized: "Home"), icon: "exit_button", color: .brown500, type: .home)
        ]
    }
    enum ForestUIState: Identifiable, Equatable {
        case option, setting, gameSelect
        case announce, forest, quest
        case updateName, empty, dailySpin
        case dailyTrack, userRoad, market
        case componentList, componentMove
        
        var id: Self { self }
    }
}

// MARK: - VIEW

struct ForestUI: View {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject var tabbarController: TabBarController
    @EnvironmentObject var router: LearningRouter
    @EnvironmentObject var bookcaseRouter: BookcaseRouter
    @EnvironmentObject private var coordinator: VocabularyForestCoordinator
    @ObservedObject var viewModel: ForestViewModel
    @State private var forestScene = ForestScene()
    
    @State private var uiState: ForestUIState = .empty
    
    @State private var componentName = ""
    @State private var selectedQuestForGame: QuestModel? = nil
    
    @AppStorage(AppStorageNames.musicVolume.rawValue) private var musicVolume: Double = 0.5
    @AppStorage(AppStorageNames.sfxVolume.rawValue) private var sfxVolume: Double = 0.8
    @AppStorage(AppStorageNames.isMuted.rawValue) private var isMuted: Bool = false
    @AppStorage(AppStorageNames.isHapticsEnabled.rawValue) private var isHapticsEnabled: Bool = true
    @AppStorage(AppStorageNames.shownForestInfo.rawValue) private var forestSeen: Bool = false
    @AppStorage(AppStorageNames.userClaimedFirtReward.rawValue) private var userClaimedFirtReward: Bool = false
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea(.all)
                .navigationBarBackButtonHidden()
                .zIndex(1.0)
                .accessibilityHidden(true)

            if uiState == .empty && userClaimedFirtReward && forestSeen {
                sceneAccessibilityOverlay.zIndex(1.05)
            }

            if !userClaimedFirtReward {
                ForestFirstRewardUI(rewards: ForestConstant.firstForestRewards) { selectedReward in
                    viewModel.claimLocalReward(model: selectedReward) {
                        userClaimedFirtReward = true
                    }
                }.zIndex(1.2)
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }else if !forestSeen {
                GameInfoUI(showForestPopUp: Binding(
                    get: { !forestSeen },
                    set: { if !$0 { forestSeen = true } }
                ))
                Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
            }
            
            if uiState != .empty {
                // componentMove leaves the scene visible so the user can watch
                // the component follow the direction buttons; market dims itself.
                if uiState != .market && uiState != .componentMove {
                    Color.black.ignoresSafeArea(.all).opacity(0.7).zIndex(1.1)
                }
                userMenu.zIndex(5.0).accessibilityAddTraits(.isModal)
            }
            
            if viewModel.showRainButton {
                VStack{
                    Spacer()
                    Button {
                        viewModel.startRain()
                    } label: {
                        Text("Start Rain").modifier(TitleBackground())
                    }.padding(.bottom, 32)
                }.zIndex(1.1)
            }
            
            if viewModel.showBookThreshold {
                ForestPopUp(
                    titleText: String(localized: "Eksik soru"),
                    descriptionText: String(localized: "Kitaplığında bu oyun için yeterli sayıda kelimele bulunmuyor. Hazır kütüphane indirerek hızlıca oynayabilirsin"),
                    onConfirm: {
                        viewModel.closeBookError()
                        tabbarController.navigateTo(tab: .bookcases)
                        bookcaseRouter.navigate(to: .bookcasePacket)
                        exitForest()
                    },
                    onDenied: { viewModel.closeBookError() },
                    confirmText: String(localized: "Kütüphane"),
                    deniedText: String(localized: "Orman"),
                    showForestPopUp: $viewModel.showBookThreshold
                ).zIndex(4.0)
            }
        }
        // Game overlays sit on fixed-size artwork; AX3 (~235%) is the largest size their
        // layouts can absorb while still exceeding the 200% Larger Text requirement.
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task {
            self.viewModel.output = forestScene
            self.forestScene.helper = viewModel
            viewModel.initalizeForest()
        }
        .onAppear {
            viewModel.updateAudioSettings(music: musicVolume, sfx: sfxVolume, isMuted: isMuted)
            viewModel.startGameMusic()
        }
        .trackScreen(.forest)
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
    
    @ViewBuilder
    var userMenu: some View {
        switch uiState {
        case .option:
            options
        case .setting:
            settings
        case .gameSelect:
            gameSelect
        case .announce:
            announcementView
        case .forest:
            ForestInfoUI(forestModel: viewModel.forestStatus) {
                uiState = .empty
            }
        case .quest:
            questView
        case .updateName:
            updateNameView
        case .dailySpin:
            dailySpinView
        case .empty:
            EmptyView()
        case .dailyTrack:
            dailyTrackView
        case .userRoad:
            userRoadView
        case .market:
            marketView
        case .componentList:
            componentListView
        case .componentMove:
            componentMoveView
        }
    }
    
    var marketView: some View {
        Group {
            if let screenModel = viewModel.marketScreenModel {
                MarketUI(
                    screenModel: screenModel,
                    isVisible: Binding(get: { uiState == .market }, set: { if !$0 { uiState = .empty } }),
                    goldBalance: viewModel.forestStatus?.gold ?? 0,
                    diamondBalance: viewModel.forestStatus?.diamond ?? 0,
                    errorMessage: viewModel.marketErrorMessage,
                    onPurchase: { item in
                        viewModel.purchaseMarketItem(item: item) {
                            PopupManager.shared.show {
                                coordinator.startClaimRewardUI(claimReward: item.reward) { rewards in
                                    viewModel.claimMarketRewards(models: rewards)
                                    PopupManager.shared.dismiss()
                                }
                            }
                        }
                    },
                    onChestInfoRequest: { chestId in
                        await viewModel.fetchChestDropInfo(chestId: chestId)
                    }
                )
            } else {
                ProgressView()
            }
        }
    }
    
    var dailySpinView: some View {
        VStack {
            DailySpinUI(
                models: viewModel.dailySpinModels,
                isVisible: Binding (get: { uiState == .dailySpin }, set: { if !$0 { uiState = .empty }}),
                nextSpinTime: $viewModel.dailySpinTime
            ) { rewardModel in
                if let reward = viewModel.resolveDailySpinReward(from: rewardModel) {
                    PopupManager.shared.show {
                        coordinator.startClaimRewardUI(claimReward: reward) { rewards in
                            viewModel.claimDailyRewards(models: rewards)
                            PopupManager.shared.dismiss()
                        }
                    }
                }else {
                    // TODO: SHOW ERROR
                }
            }
            .id(viewModel.dailySpinModelVersion)
        }
             
    }
    
    var dailyTrackView: some View {
        WeeklyRewardUI(isOpen: Binding ( get: { uiState == .dailyTrack }, set: { newValue in
            if !newValue { uiState = .empty }
        }), cardList: viewModel.weeklyDailyCards) { dailyModel in
            if dailyModel.status == .ready {
                PopupManager.shared.show {
                    coordinator.startClaimRewardUI(claimReward: dailyModel.bounty) { rewards in
                        viewModel.claimWeeklyRewards(models: rewards, weeklyModel: dailyModel)
                        PopupManager.shared.dismiss()
                    }
                }
            }
        }
    }
    
    var userRoadView: some View {
        Group {
            if let screenModel = viewModel.adventureRoadScreenModel {
                AdventureRoadUI(
                    screenModel: screenModel,
                    isVisible: Binding(get: { uiState == .userRoad }, set: { if !$0 { uiState = .empty } })
                ) { milestone in
                    if milestone.status == .ready {
                        PopupManager.shared.show {
                            coordinator.startClaimRewardUI(claimReward: milestone.reward) { rewards in
                                viewModel.claimAdventureRewards(models: rewards, milestone: milestone)
                                PopupManager.shared.dismiss()
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }
    
    var announcementView: some View {
        ForestAnnouncementUI(
            isVisible: Binding(
                get: { uiState == .announce },
                set: { newValue in
                    if newValue == false && uiState == .announce {
                        uiState = .empty
                    }
                }
            ),
            claimableTypes: viewModel.claimableAnnouncementTypes
        ) { model in
            switch model {
            case .tasks:
                uiState = .quest
            case .dailyReward:
                viewModel.fetchWeeklyDailyCards()
                uiState = .dailyTrack
            case .dailySpin:
                viewModel.checkDailySpinStatus()
                viewModel.refreshDailySpinRewards()
                uiState = .dailySpin
            case .adventureRoad:
                uiState = .userRoad
                viewModel.fetchAdventureRoadData()
            }
        }
    }
    
    var questView: some View {
        ForestQuestUI(
            showQuest: Binding(
                get: { uiState == .quest },
                set: { if !$0  { uiState = .empty } }
            ),
            selectQuest: { model in
                selectedQuestForGame = model
                uiState = .gameSelect
            },
            dailyQuests: viewModel.dailyQuestList,
            weeklyQuests: viewModel.weeklyQuestList,
            monthlyQuests: viewModel.monthlyQuestList,
            specialQuests: viewModel.specialQuestList
        ) { model in
            viewModel.claimQuestReward(quest: model)
        }
    }
    
    var gameSelect: some View {
        GameSelectUI(
            initialQuest: selectedQuestForGame,
            showGameSelect: Binding(
                get: { uiState == .gameSelect },
                set: { if !$0 { uiState = .empty } }
            ),
            bookcaseList: viewModel.bookcaseList,
            startGame: { type, mode, level, questionSelection in
                if viewModel.checkBookCount(type: type, battleMode: mode, gameLevel: level, bookcaseSelection: questionSelection) {
                    selectedQuestForGame = nil
                    uiState = .empty
                    switch questionSelection {
                    case .allBookcases:
                        router.navigate(to: .game(type, mode, level, nil))
                    case .spesific(let model):
                        router.navigate(to: .game(type, mode, level, model))
                    }
                }
            }
        )
        .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
    }
    
    var updateNameView: some View {
        VStack {
            Text("Update name").foregroundStyle(.white).scaledFont(size: 20)
            HStack {
                Spacer()
                Button {
                    uiState = .empty
                } label: {
                    Image(.closeButton).resizable().scaledToFit().frame(maxWidth: 32)
                        .accessibilityLabel(String(localized: "a11y_close"))
                }
                TextField("Name", text: $componentName)
                    .frame(maxWidth: 180).padding(.vertical,8).padding(.horizontal)
                    .background(.brown300.opacity(0.9)).cornerRadius(16)
                Button {
                    viewModel.updateComponentName(name: componentName)
                    uiState = .empty
                } label: {
                    Image(.acceptButton).resizable().scaledToFit().frame(maxWidth: 32)
                        .accessibilityLabel(String(localized: "a11y_confirm"))
                }
                Spacer()
            }
        }
        .compositingGroup()
    }
    
    var componentListView: some View {
        VStack {
            ZStack {
                Image("title_header").resizable().scaledToFit()
                Text("Orman bileşenleri").foregroundStyle(.white).scaledFont(size: 20)
            }
            if viewModel.forestComponents.isEmpty {
                Text("Ormanda yönetilecek bileşen yok")
                    .foregroundStyle(.white).scaledFont(size: 16)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.forestComponents) { component in
                            componentRow(component)
                        }
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
            }
        }
        .padding().background(.brown.opacity(0.8)).cornerRadius(16)
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .overlay(alignment: .topTrailing) {
            Button {
                uiState = .empty
            } label: {
                Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
                    .accessibilityLabel(String(localized: "a11y_close"))
            }
        }
    }

    func componentRow(_ component: ForestComponentSummary) -> some View {
        HStack(spacing: 8) {
            Text(component.name)
                .foregroundStyle(.white).scaledFont(size: 16)
                .lineLimit(2)
            Spacer()
            componentRowAction(String(localized: "Adını değiştir")) {
                componentName = component.name
                viewModel.setComponent(uuid: component.id, for: component.type)
                uiState = .updateName
            }
            if component.supportsMove {
                componentRowAction(String(localized: "Taşı")) {
                    if forestScene.beginPositionChange(id: component.id, type: component.type) {
                        uiState = .componentMove
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    func componentRowAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundStyle(.white).scaledFont(size: 14)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(.brown300.opacity(0.9))
                .cornerRadius(12)
        }
    }

    /// Direction pad for moving a component without touching the scene —
    /// binds 1:1 to the same scene calls the arrow sprites used to trigger.
    var componentMoveView: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                moveStepButton(ForestConstant.upIconName, label: String(localized: "a11y_move_up"), direction: .up)
                HStack(spacing: 24) {
                    moveStepButton(ForestConstant.leftIconName, label: String(localized: "a11y_move_left"), direction: .left)
                    moveStepButton(ForestConstant.downIconName, label: String(localized: "a11y_move_down"), direction: .down)
                    moveStepButton(ForestConstant.rightIconName, label: String(localized: "a11y_move_right"), direction: .right)
                }
                HStack(spacing: 48) {
                    moveControlButton(ForestConstant.refuseIconName, label: String(localized: "a11y_close")) {
                        forestScene.cancelPositionChange()
                        uiState = .empty
                    }
                    moveControlButton(ForestConstant.confirmIconName, label: String(localized: "a11y_confirm")) {
                        forestScene.confirmPositionChange()
                        uiState = .empty
                    }
                }
            }
            .padding()
            .background(.brown.opacity(0.8))
            .cornerRadius(16)
            .padding(.bottom, 24)
        }
    }

    func moveStepButton(_ icon: String, label: String, direction: Directions) -> some View {
        moveControlButton(icon, label: label) {
            forestScene.applyMoveStep(direction)
        }
    }

    func moveControlButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(icon).resizable().scaledToFit().frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
    }

    /// Bridge for the SpriteKit menu column: real (transparent) buttons sit exactly
    /// over the scene sprites using the shared ForestConstant geometry, so finger
    /// taps, VoiceOver activation and Voice Control's synthetic taps all travel the
    /// same path. The sprites stay purely visual.
    var sceneAccessibilityOverlay: some View {
        GeometryReader { geo in
            let side = max(geo.size.height * ForestConstant.menuButtonRelativeSize, ForestConstant.menuButtonMinSize)
            ForEach(Array(sceneMenuEntries.enumerated()), id: \.offset) { index, entry in
                Button(action: entry.action) {
                    Color.clear
                        .frame(width: side, height: side)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(entry.label)
                .position(
                    x: geo.size.width * ForestConstant.menuButtonRelativeX,
                    // SpriteKit's origin is bottom-left, SwiftUI's is top-left.
                    y: geo.size.height * (1 - ForestConstant.menuButtonRelativeYs[index])
                )
            }
        }
        .ignoresSafeArea()
    }

    var sceneMenuEntries: [(label: String, action: () -> Void)] {
        [
            (String(localized: "a11y_menu"), showOptions),
            (String(localized: "a11y_adventure_board"), showAnnouncement),
            (String(localized: "a11y_play_game"), showGameSelection),
            (String(localized: "a11y_forest_info"), showForestInfo),
            (String(localized: "a11y_market"), showMarket)
        ]
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
                Text("Options").foregroundStyle(.white).scaledFont(size: 24)
            }
            ForEach(Constant.optionsList, id: \.self) { model in
                settingsRow(model: model).onTapGesture {
                    switch model.type {
                    case .resume:
                        uiState = .empty
                    case .settings:
                        uiState = .setting
                    case .home:
                        uiState = .empty
                        exitForest()
                    case .info:
                        uiState = .empty
                        forestSeen = false
                    case .components:
                        uiState = .componentList
                    }
                }
                .a11yTapButton(model.title)
            }
        }
        .padding().background(.brown.opacity(0.8)).cornerRadius(16).frame(width: UIScreen.main.bounds.width * 0.6)
        .overlay(alignment: .topTrailing) {
            Button {
                uiState = .empty
            } label: {
                Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
                    .accessibilityLabel(String(localized: "a11y_close"))
            }
        }
    }
    
    var settings: some View {
        VStack(spacing: 20) {
            ZStack {
                Image("title_header").resizable().scaledToFit().frame(height: 50)
                Text("Settings").foregroundStyle(.white).scaledFont(size: 24, weight: .bold)
            }
            .padding(.bottom, 10)
            
            VStack(spacing: 24) {
                Group {
                    customSliderRow(title: String(localized: "Music"), icon: "music.note", value: $musicVolume)
                        .disabled(isMuted)
                        .opacity(isMuted ? 0.5 : 1.0)
                    customSliderRow(title: String(localized: "SFX"), icon: "speaker.wave.2.fill", value: $sfxVolume)
                        .disabled(isMuted)
                        .opacity(isMuted ? 0.5 : 1.0)
                    customToggleRow(title: String(localized: "Mute All"), icon: "speaker.slash.fill", isOn: $isMuted)
                }
                
                Divider().background(Color.white.opacity(0.5))
                Group {
                    customToggleRow(title: String(localized: "Haptics"), icon: "iphone.radiowaves.left.and.right", isOn: $isHapticsEnabled)
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
        .frame(width: UIScreen.main.bounds.width * 0.7)
        .overlay(alignment: .topTrailing) {
            Button {
                uiState = .empty
            } label: {
                Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
                    .accessibilityLabel(String(localized: "a11y_close"))
            }
        }
    }
}

// MARK: - HELPERS

private extension ForestUI {
    
    func openQuestGame(model: QuestModel) {
        uiState = .gameSelect
    }
    
    func exitForest() {
        viewModel.stopGameMusic()
        router.navigateToRoot()
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension ForestUI: ForestUIProtocol {
    
    func showMarket() {
        viewModel.marketErrorMessage = nil
        uiState = .market
    }
    
    func updateComponentName(model: any ComponentNameable, type: ComponentType) {
        componentName = model.characterName
        viewModel.setComponent(uuid: model.id, for: type)
        uiState = .updateName
    }
    
    func showForestInfo() {
        uiState = .forest
    }
    
    func showGameSelection() {
        uiState = .gameSelect
    }
    
    func showAnnouncement() {
        uiState = .announce
    }
    
    func hideOptions() {
        uiState = .empty
    }
    func showOptions() {
        uiState = .option
    }
}

#Preview {
    let resolver = DC.shared
    let coordinator = VocabularyForestCoordinator(resolver: resolver)
    coordinator.startForestUI()
}
