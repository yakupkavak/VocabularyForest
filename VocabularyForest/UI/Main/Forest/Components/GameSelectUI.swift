//
//  GameSelectUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 8.12.2025.
//

import SwiftUI

extension GameSelectUI {
    enum Constant {
        static let gameTypes: [BattleModeModel] = [.classic,.fireDragon,.sandDragon,.fireElemental,.iceElemental,.natureElemental]
        static let gameLevels: [GameLevel] = [.easy,.medium,.hard,.insane]
        static let gameMode: [BattleQuestionType] = [.learning,.competitive,.remainder]
    }
}

struct GameSelectUI: View {
    
    // MARK: - PROPERTIES
    
    @Binding var showGameSelect: Bool
    @State private var selectedMode: BattleModeModel = .iceElemental
    @State private var selectedLevel: GameLevel = .easy
    @State private var selectedType: BattleQuestionType = .learning
    var startGame: (BattleQuestionType, BattleModeModel, GameLevel) -> Void
    
    // MARK: - UI

    var body: some View {
        VStack(spacing: 8) {
           
            VStack{
                Text("Games").foregroundStyle(.white).font(.system(size: 24, weight: .bold)).padding(.horizontal, 12).padding(.vertical, 8)
            }
            .background(
                Image("title_header").resizable()
            ).padding(.top, -4)
            
            ZStack(alignment: .center) {
                // TODO: - PLAY IDLE ANIMATION
                Image(selectedMode.background).resizable().scaledToFill().frame(width: .infinity, height: UIScreen.main.bounds.height * 0.2).borderRadius(borderColor: .white)
                Image("\(selectedMode.valueForCoreData.lowercased())_idle_0").resizable().scaledToFit().scaleEffect(x: -1, y: 1).frame(maxHeight: UIScreen.main.bounds.width * 0.3 )
            }
            Text("Game Types").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold).foregroundStyle(.white)
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
            Text("Game Levels").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold).foregroundStyle(.white)
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
                }) ? "You can defeat the enemies with \(selectedLevel.enemyLevel) correct selections, and the boss with \(selectedLevel.bossLevel) correct selections and you have \(selectedLevel.playerLevel) health"
                : "You can defeat the enemy with \(selectedLevel.bossLevel) correct selections and you have \(selectedLevel.playerLevel) health"
            ).frame(maxWidth: .infinity, alignment: .leading).fontWeight(.medium).foregroundStyle(.white.opacity(0.8)).font(.system(size: 14))
                .multilineTextAlignment(.leading)
            
            Text("Game Mode").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold).foregroundStyle(.white)
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
            Text("\(selectedType.description)").frame(maxWidth: .infinity, alignment: .leading).fontWeight(.medium).font(.system(size: 14)).foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
            
            Button(action: {
                startGame(selectedType, selectedMode, selectedLevel)
            }, label: {
                Text("Start Game").fontWeight(.bold).foregroundStyle(.white)
            })
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.vertical, 8).background(Image("title_header")
                .resizable()
                .colorMultiply(.yellow)
                .opacity(0.5)
            )
        }
        .padding(24)
        .background(Color.brown.opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("brown300"), lineWidth: 4)
        )
        .zIndex(3.0)
        .frame(width: UIScreen.main.bounds.width * 0.9)
        .overlay(alignment: .topTrailing) {
            Button {
                showGameSelect = false
            } label: {
                Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
            }
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
            Text(tag)
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
    GameSelectUI(showGameSelect: $gameSelect) {
        otpion, game, level in
        print("yakup")
    }
}
