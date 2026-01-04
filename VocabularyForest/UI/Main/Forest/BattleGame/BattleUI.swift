//
//  Untitled.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SwiftUI
import SpriteKit
internal import CoreData

// MARK: - CONSTANTS

private enum BattleConstantUI {
    static let optionsList: [SettingsModel<SettingType>] = [
        SettingsModel(title: "Resume", icon: "forward_button", color: .brown500, type: .resume),
        SettingsModel(title: "Settings", icon: "settings_button", color: .brown500, type: .settings),
        SettingsModel(title: "Home", icon: "exit_button", color: .brown500, type: .home)
    ]
}

struct BattleUI<ViewModel>: View where ViewModel: BattleViewModelProtocol {
    
    // MARK: - PROPERTIES
    
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @AppStorage(AppStorageNames.musicVolume.rawValue) private var musicVolume: Double = 0.5
    @AppStorage(AppStorageNames.sfxVolume.rawValue) private var sfxVolume: Double = 0.8
    @AppStorage(AppStorageNames.isMuted.rawValue) private var isMuted: Bool = false
    @AppStorage(AppStorageNames.isHapticsEnabled.rawValue) private var isHapticsEnabled: Bool = true
    @StateObject private var viewModel: ViewModel
    @EnvironmentObject private var forestRouter: LearningRouter
    @State private var showMagics = true
    @State private var showQuestion = false
    @State private var showOption = false
    @State private var showSetting = false
    @State private var showExistAlert = false
    @State private var scene: BattleScene
    var gameType: BattleQuestionType
    var battleMode: BattleEnemyModel
    var gameLevel: GameLevel
    
    // MARK: - INIT
    
    init(
        viewModel: @autoclosure @escaping () -> ViewModel,
        gameType: BattleQuestionType,
        battleMode: BattleEnemyModel,
        gameLevel: GameLevel,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.gameType = gameType
        self.battleMode = battleMode
        self.gameLevel = gameLevel
        let battleScene = BattleScene(enemyModel: battleMode)
        self._scene = State(wrappedValue: battleScene)
    }
    
    // MARK: - UI
    
    var body: some View {
        ZStack() {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            VStack {
                headerView.padding(.top, safeAreaInsets.top)
                Spacer()
            }
            .zIndex(3.0)
            if showOption {
                if showExistAlert {
                    GameConfirmationUI(title: "Are you sure?", message: "Your progress won't be saved") {
                        forestRouter.navigateBack()
                    } onCancel: {
                        showExistAlert = false
                    }.transition(.scale)
                        .zIndex(3.0)
                }else {
                    GameOptionsUI(
                        onResume: { showOption = false },
                        onSettings: {
                            showOption = false
                            showSetting = true
                        },
                        onHome: {
                            showExistAlert = true
                        },
                        onClose: { showOption = false }
                    )
                    .transition(.scale)
                    .zIndex(3.0)
                }
                Color.black.ignoresSafeArea().opacity(0.7).zIndex(2.0)
            }else if showSetting {
                ForestSettingsUI(onClose: { showSetting = false })
                    .transition(.scale)
                    .zIndex(3.0)
                Color.black.ignoresSafeArea().opacity(0.7).zIndex(2.0)
            }
            if let error = viewModel.errorModel {
                switch error {
                case .emptyBookcase:
                    Text("emptyBookcase").foregroundStyle(.white)
                case .emptyQuestionList:
                    Text("emptyQuestionList").foregroundStyle(.white)
                case .unexpectedError:
                    Text("unexpectedError").foregroundStyle(.white)
                case .emptyEnemyAsset:
                    Text("emptyEnemyAsset").foregroundStyle(.white)
                }
            }else {
                ZStack{
                    switch viewModel.uiStation {
                    case .askQuestion:
                        questionView
                    case .chooseMagic:
                        magicSelectionView
                    case .notDetermined:
                        EmptyView()
                    case .checkAnswer:
                        if viewModel.questionStation == .correct {
                            Text("correct")
                        }else if viewModel.questionStation == .wrong {
                            Text("wrong")
                        }
                    case .gameOver:
                        gameOverView
                    }
                }.ignoresSafeArea(.all)
            }
        }
        .task {
            self.viewModel.output = scene
            self.scene.helper = viewModel
            self.viewModel.prepareGame(bookcase: nil, questionType: gameType, battleMode: battleMode, gameLevel: gameLevel)
        }.onAppear {
            viewModel.updateAudioSettings(music: musicVolume, sfx: sfxVolume, isMuted: isMuted)
            //viewModel.startGameMusic()
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

private extension BattleUI {
    
    var magicSelectionView: some View {
        ZStack {
            Image("pop_up_background").resizable()
            Spacer()
            VStack(alignment: .center) {
                HStack {
                    ForEach(BattleConstant.allMagicList.prefix(3), id: \.self) { magic in
                        let magicModel = magic.model
                        VStack {
                            Image(magicModel.image).resizable().cornerRadius(8).frame(width: UIScreen.main.bounds.width * 0.1, height: UIScreen.main.bounds.width * 0.1)
                                .onTapGesture {
                                    showMagics = false
                                    viewModel.startMagic(magicType: magic)
                                }
                            Text(magicModel.name).foregroundStyle(.white).foregroundStyle(.white).multilineTextAlignment(.center)
                            Spacer()
                        }.padding(.horizontal, 12)
                    }
                }
                HStack {
                    ForEach(BattleConstant.allMagicList.dropFirst(3), id: \.self) { magic in
                        let magicModel = magic.model
                        VStack {
                            Image(magicModel.image).resizable().cornerRadius(8).frame(width: UIScreen.main.bounds.width * 0.1, height: UIScreen.main.bounds.width * 0.1).onTapGesture {
                                showMagics = false
                                viewModel.startMagic(magicType: magic)
                            }
                            Text(magicModel.name).foregroundStyle(.white).foregroundStyle(.white).multilineTextAlignment(.center)
                        }.padding(.horizontal, 16)
                    }
                }
            }.frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.2)
                
        }.frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.3).overlay(alignment: .top) {
            ZStack {
                Image("pop_up_title_window").resizable().scaledToFit()
                Text("Select your \nMagic").foregroundStyle(.white).multilineTextAlignment(.center)
            }.frame(maxHeight: UIScreen.main.bounds.height * 0.1).offset(y: -UIScreen.main.bounds.height * 0.06)
        }
    }
    
    var questionView: some View {
        VStack {
            Spacer()
            if let question = viewModel.currentQuestion {
                ZStack {
                    Image("pop_up_background").resizable()
                    Spacer()
                    VStack(alignment: .center) {
                        Text(question.questionTitle).foregroundStyle(.white).multilineTextAlignment(.center)
                        if gameType == .learning {
                            if let example = question.example, !example.isEmpty {
                                Text("Örnek").foregroundStyle(.white).multilineTextAlignment(.center).font(.system(size: 12)).padding(.top, 4)
                                Text(example).foregroundStyle(.white).multilineTextAlignment(.center).font(.system(size: 13))
                            } else {
                                if let description = question.description, !description.isEmpty {
                                    Text("Açıklama").foregroundStyle(.white).multilineTextAlignment(.center).font(.system(size: 12)).padding(2)
                                    Text(description).foregroundStyle(.white).multilineTextAlignment(.center).font(.system(size: 13))
                                }
                            }
                        }
                    }.frame(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.height * (gameType == .learning ? 0.25 : 0.2))
                }.frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.2) .overlay(alignment: .top) {
                    ZStack {
                        Image("pop_up_title_window").resizable().scaledToFit()
                        let questionString = NSLocalizedString("question_number", comment: "")
                        let finalString = String(format: questionString, question.questionNumber)
                        Text(finalString).foregroundStyle(.white).multilineTextAlignment(.center)
                    }.frame(maxHeight: UIScreen.main.bounds.height * 0.1).offset(y: -UIScreen.main.bounds.height * 0.07)
                }
                Spacer()
                VStack() {
                    HStack{
                        Spacer()
                        answerComponent(text: question.answers[0].answer).onTapGesture {
                            viewModel.checkAnswer(answerNumber: 0)
                        }
                        Spacer()
                        answerComponent(text: question.answers[1].answer).onTapGesture {
                            viewModel.checkAnswer(answerNumber: 1)
                        }
                        Spacer()
                    }
                    HStack{
                        Spacer()
                        answerComponent(text: question.answers[2].answer).onTapGesture {
                            viewModel.checkAnswer(answerNumber: 2)
                        }
                        Spacer()
                        answerComponent(text: question.answers[3].answer).onTapGesture {
                            viewModel.checkAnswer(answerNumber: 3)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(.bottom)
    }
    
    var gameOverView: some View {
        ZStack {
            Image("pop_up_background").resizable()
            Spacer()
            VStack(alignment: .center) {
                VStack{
                    if viewModel.gameStatus.wrongWords.isEmpty {
                        Text("Amazing!!\nYou remembered everything!").multilineTextAlignment(.center).foregroundStyle(.white).padding()
                    }else {
                        Text("Review  wrong words").multilineTextAlignment(.center).foregroundStyle(.white).font(.headline).padding()
                        List {
                            ForEach(viewModel.gameStatus.wrongWords) { book in
                                Text(book.unwrappedLearningWord).foregroundStyle(.white).listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }.padding(.horizontal).listRowInsets(.none).listRowSeparator(.hidden, edges: .all)
                            .listStyle(.plain)
                            .background(.clear)
                            .scrollContentBackground(.hidden)
                    }
                }
                Button {
                    forestRouter.navigateBack()
                } label: {
                    Text("Return Forest")
                }.buttonStyle(.plain).foregroundStyle(.clickableText).font(.headline).padding()

            }.frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.27)
                
        }.frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.3).overlay(alignment: .top) {
            ZStack {
                Image("pop_up_title_window").resizable().scaledToFit()
                Text(viewModel.gameStatus.userWon ?? true ? "Fantastic!" : "So Close!").foregroundStyle(.white).multilineTextAlignment(.center)
            }.frame(maxHeight: UIScreen.main.bounds.height * 0.1).offset(y: -UIScreen.main.bounds.height * 0.078)
        }
    }
    
    var headerView: some View {
        VStack() {
            HStack {
                if let playerAnger = viewModel.playerAnger {
                    VStack {
                        Image("player_title_header").resizable().scaledToFit().overlay{
                            Text(playerAnger.name).foregroundStyle(.white).padding(4)
                        }.frame(width: UIScreen.main.bounds.width * 0.4)
                        ZStack {
                            Image("loading_bar_background").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width * 0.46).zIndex(1.0)
                            Image("loading_bar_fill_blue").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width * 0.46).mask {
                                GeometryReader { geo in
                                    Rectangle().frame(width: geo.size.width * (CGFloat(viewModel.playerAnger?.currentLevel ?? 1) / CGFloat( viewModel.playerAnger?.totalLevel ?? 1)))
                                }
                            }.zIndex(2.0)
                        }
                    }
                }
                Spacer()
                if let enemyAnger = viewModel.enemyAnger {
                    VStack {
                        Image("enemy_title_header").resizable().scaledToFit().overlay{
                            Text(enemyAnger.name).foregroundStyle(.white).padding(4)
                        }.frame(width: UIScreen.main.bounds.width * 0.4)
                        ZStack {
                            Image("loading_bar_background").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width * 0.46).zIndex(1.0)
                            Image("loading_bar_fill_red").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width * 0.46).mask {
                                GeometryReader { geo in
                                    Rectangle().frame(width: geo.size.width * (CGFloat(viewModel.enemyAnger?.currentLevel ?? 1) / CGFloat( viewModel.enemyAnger?.totalLevel ?? 1)))
                                }
                            }.zIndex(2.0)
                        }
                    }
                }
            }
            HStack {
                Spacer()
                Image("menu_button").resizable().scaledToFit().frame(maxWidth: 36).onTapGesture {
                    showOption = true
                }
            }
        }.ignoresSafeArea(edges: .horizontal).padding(.trailing, 8)
    }
    
    var options: some View {
        VStack {
            ZStack {
                Image("title_header").resizable().scaledToFit()
                Text("Options").foregroundStyle(.white).font(.system(size: 24))
            }
            ForEach(BattleConstantUI.optionsList, id: \.self) { model in
                settingsRow(model: model).onTapGesture {
                    switch model.type {
                    case .resume:
                        showOption = false
                    case .settings:
                        showOption = false
                        showSetting = true
                    case .home:
                        showOption = false
                        showExistAlert = true
                    case .info:
                        print("nil")
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
    
    func answerComponent(text: String) -> some View {
        ZStack {
            Image(.popUpBackground).resizable().frame(width: UIScreen.main.bounds.width * 0.35, height: UIScreen.main.bounds.width * 0.2).opacity(0.9)
            Text(text).foregroundStyle(.white).frame(width: UIScreen.main.bounds.width * 0.33, height: UIScreen.main.bounds.height * 0.11).multilineTextAlignment(.center)
        }
    }
}

// MARK: - GAME HELPERS

private extension BattleUI {
    func exitGame() {
        showExistAlert = true
    }
}

#Preview {
    let previewManager = CoreDataManager.preview
    let context = previewManager.viewContext
    let sampleBookcase = Bookcase(context: context)
    sampleBookcase.name = "Test Kitaplık"
    sampleBookcase.learningLanguage = "en"
    sampleBookcase.meaningLanguage = "tr"
    sampleBookcase.createdDate = Date()
    for i in 1...100 {
        let sampleBook = Book(context: context)
        sampleBook.learningWord = "Word \(i)"
        sampleBook.meaningWord = "Anlam \(i)"
        sampleBook.createdDate = Date()
        sampleBook.shortMemory = i % 2 == 0
        sampleBook.longMemory = i % 2 != 0
        sampleBook.bookcase = sampleBookcase
    }
    try? context.save()
    let viewModel = BattleViewModel(coreDataManager: previewManager)
    return BattleUI(viewModel: viewModel, gameType: .competitive, battleMode: .natureElemental, gameLevel: .easy)
}
