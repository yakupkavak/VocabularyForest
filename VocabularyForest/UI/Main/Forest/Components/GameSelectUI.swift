//
//  GameSelectUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 8.12.2025.
//

import SwiftUI

extension GameSelectUI {
    enum Constant {
        static let gameTypes: [BattleEnemyModel] = [.classic,.fireDragon,.sandDragon,.fireElemental,.iceElemental,.natureElemental]
        static let gameLevels: [GameLevel] = [.easy,.medium,.hard,.insane]
        static let gameMode: [BattleQuestionType] = [.learning,.competitive,.remainder]
    }
}

protocol GameSelectUIProtocol {
    func selectGame(model: QuestModel)
}

enum GameBookcaseSelection {
    case allBookcases
    case spesific(BookcaseModel)
}

struct GameSelectUI: View {
    
    // MARK: - PROPERTIES
    
    var initialQuest: QuestModel?
    @Binding var showGameSelect: Bool
    var bookcaseList: [Bookcase]
    @State private var selectedMode: BattleEnemyModel = .classic
    @State private var selectedLevel: GameLevel = .easy
    @State private var selectedType: BattleQuestionType = .learning
    @State private var showSelectBookcase = false
    @State private var selectedBookcase: BookcaseModel? = nil
    @State private var emptyBookcase = false
    @State private var selectAllBookcase = false
    var startGame: (BattleQuestionType, BattleEnemyModel, GameLevel, GameBookcaseSelection) -> Void
    
    // MARK: - UI

    var body: some View {
        VStack {
            Text("Oyunlar").foregroundStyle(.white).font(.system(size: 24, weight: .bold)).padding(.horizontal, 12).padding(.vertical, 8).background(
                Image("title_header").resizable()
            )
            ZStack(alignment: .center) {
                // TODO: - PLAY IDLE ANIMATION
                Image(selectedMode.background).resizable().scaledToFill().frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.18).borderRadius(borderColor: .white)
                Image("\(selectedMode.valueForCoreData.lowercased())_idle_0").resizable().scaledToFit().scaleEffect(x: -1, y: 1).frame(maxHeight: UIScreen.main.bounds.width * 0.3 )
            }
            ScrollView(showsIndicators: false) {
                Text("Oyun çeşitleri").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold).foregroundStyle(.white).padding(.top, 4)
                FlowLayout {
                    ForEach(Constant.gameTypes, id: \.self) { game in
                        TagView(tag: game.title, isSelected: Binding(
                            get: { selectedMode == game },
                            set: { isSelected in
                                if isSelected {
                                    selectedMode = game
                                }
                            }
                        ))
                    }
                }
                Text("Seviyeler").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold).foregroundStyle(.white).padding(.top, 4)
                FlowLayout {
                    ForEach(Constant.gameLevels, id: \.self) { level in
                        TagView(tag: level.title, isSelected: Binding(
                            get: { selectedLevel == level },
                            set: { isSelected in
                                if isSelected {
                                    selectedLevel = level
                                }
                            }
                        ))
                    }
                }
                Text(
                    selectedMode.assetModels.contains(where: { (model: EnemyCharacterModel) in
                        return !model.isBoss
                    }) ? "Düşmanları \(selectedLevel.enemyLevel), Patronu ise \(selectedLevel.bossLevel) doğru seçimle yenebilirsin. \(selectedLevel.playerLevel) canın var."
                    : "Düşmanı \(selectedLevel.bossLevel) doğru seçimle yenebilirsin. \(selectedLevel.playerLevel) canın var."
                ).frame(maxWidth: .infinity, alignment: .leading ).fontWeight(.medium).foregroundStyle(.white.opacity(0.8)).font(.system(size: 14))
                    .multilineTextAlignment(.leading)
                
                Text("Oyun Modu").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold).foregroundStyle(.white).padding(.top, 4)
                FlowLayout {
                    ForEach(Constant.gameMode, id: \.self) { level in
                        TagView(tag: level.title, isSelected: Binding(
                            get: { selectedType == level },
                            set: { isSelected in
                                if isSelected {
                                    selectedType = level
                                }
                            }
                        ))
                    }
                }
                Text(LocalizedStringKey("\(selectedType.description)")).frame(maxWidth: .infinity, alignment: .leading).fontWeight(.medium).font(.system(size: 14)).foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                
                Text("Kitaplık").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold).foregroundStyle(.white).padding(.vertical, 4)
                Text(selectedType == .learning ? "Oyuna başlayabilmek için içerisinde örnek ya da açıklama bulunan en az \(calculateMinBookCount(battleMode: selectedMode, gameLevel: selectedLevel)) kelimeye ihtiyacın var." : "Oyuna başlayabilmek için en az \(calculateMinBookCount(battleMode: selectedMode, gameLevel: selectedLevel)) kelimeye ihtiyacın var.").frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.medium).foregroundStyle(.white.opacity(0.8)).font(.system(size: 14))
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Button {
                        showSelectBookcase = true
                    } label: {
                        Text(LocalizedStringKey("\(selectedBookcase?.bookcaseName ?? String(localized: "Kitaplık seçiniz"))"))
                            .fixedSize()
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .foregroundColor(.white)

                    }
                    .background(Image("title_header")
                        .resizable()
                        .colorMultiply(.green)
                        .cornerRadius(16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(emptyBookcase ? Color.red : Color.yellow, lineWidth: 2)
                    )
                    Toggle("Tüm kitaplarla oyna", isOn: $selectAllBookcase).toggleStyle(MyToggleStyle3()).foregroundColor(.white).font(.system(size: 13, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 1)
                
                Button(action: {
                    if(selectedBookcase == nil && selectAllBookcase == false) {
                        emptyBookcase = true
                    }else {
                        if selectAllBookcase {
                            startGame(selectedType, selectedMode, selectedLevel, .allBookcases)
                        }else {
                            if let selectedBookcase {
                                startGame(selectedType, selectedMode, selectedLevel, .spesific(selectedBookcase))
                            }
                        }
                    }
                }, label: {
                    Text("Oyuna Başla").fontWeight(.bold).foregroundStyle(.white)
                })
                .buttonStyle(.plain)
                .padding(.horizontal, 16).padding(.vertical, 8).background(Image("title_header")
                    .resizable()
                    .colorMultiply(.yellow)
                    .opacity(0.5)
                )
            }
        }
        .padding(16)
        .background(Color.brown.opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("brown300"), lineWidth: 4)
        )
        .zIndex(3.0)
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .overlay(alignment: .topTrailing) {
            Button {
                showGameSelect = false
            } label: {
                Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
            }
        }
        .sheet(isPresented: $showSelectBookcase) {
            SelectBookcaseUI(allBookcases: bookcaseList, selectedBookcase: $selectedBookcase)
        }
        .task {
            if let initialQuest {
                selectGame(model: initialQuest)
            }
        }
        .onChange(of: selectedBookcase) { bookcase in
            if bookcase == nil {
                selectAllBookcase = true
            }else {
                selectAllBookcase = false
            }
        }
    }
}

extension GameSelectUI: GameSelectUIProtocol {
    func selectGame(model: QuestModel) {
        selectedMode = model.battleEnemyModel
        selectedLevel = model.gameLevel
        selectedType = model.questionType
    }
}

struct MyToggleStyle3: ToggleStyle {
    let width: CGFloat = 40
    
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(spacing: 20) {
            configuration.label

            ZStack(alignment: configuration.isOn ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: width / 2, height: width )
                    .foregroundColor(configuration.isOn ? .logoGreen : .brown500)
                
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: (width / 2) - 4, height: width / 2 - 6)
                    .padding(4)
                    .foregroundColor(.white)
                    .rotationEffect(configuration.isOn ? .degrees(0): .degrees(180))
                    .onTapGesture {
                        withAnimation {
                            configuration.$isOn.wrappedValue.toggle()
                        }
                }
            }.rotationEffect(.degrees(90))
        }
    }
}

struct TagView: View {
    let tag: String
    @Binding var isSelected: Bool

    var body: some View {
        Button {
            withAnimation {
                isSelected.toggle()
            }
        } label: {
            Text(LocalizedStringKey(tag))
                .fixedSize()
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .background(Image("title_header")
            .resizable()
            .colorMultiply(isSelected ? .green : .white)
            .opacity(isSelected ? 1.0 : 0.7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        ).padding(3)
    }
}

#Preview {
    @State var gameSelect = true
    GameSelectUI(showGameSelect: $gameSelect, bookcaseList: []) {
        otpion, game, level, type  in
        print("yakup")
    }
}
