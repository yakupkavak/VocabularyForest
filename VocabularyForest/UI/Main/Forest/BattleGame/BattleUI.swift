//
//  Untitled.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SwiftUI
import SpriteKit

protocol BattleUIProtocol {
    func showMagicSelection()
}

protocol BattleUIOutputProcotol {
    func startMagic(magic: MagicType)
    func enemyAttack()
}

struct BattleUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject var viewModel = BattleViewModel()
    @State private var scene: BattleScene = {
        let scene = BattleScene()
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .fill
        return scene
    }()
    
    @State private var showMagics = false
    @State var battleOutput: BattleUIOutputProcotol?
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            if showMagics {
                magicSelectionView
            }
        }.task {
            self.battleOutput = scene
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
                                    battleOutput?.startMagic(magic: magic)
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
                                battleOutput?.startMagic(magic: magic)
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
}

extension BattleUI: BattleUIProtocol {
    func showMagicSelection() {
        showMagics = true
    }
}

#Preview {
    BattleUI()
}
