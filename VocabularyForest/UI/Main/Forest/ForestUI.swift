//
//  ForestUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//
 
import SwiftUI
import SpriteKit

struct ForestUI: View { 
    
    // MARK: - PROPERTIES
    
    @StateObject private var viewModel = ForestViewModel()
    
    // MARK: - UI
    
    var body: some View { 
        SpriteView(scene: gameScene)
            .ignoresSafeArea(.all)
            .navigationBarBackButtonHidden()
    } 
}

// MARK: - UI COMPONENTS

private extension ForestUI {
    var gameScene: SKScene {
        let gameView = GameScene()
        gameView.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        gameView.scaleMode = .fill
        return gameView
    }
}

#Preview {
    ForestUI()
}
