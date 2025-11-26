//
//  BattleEnvironmentManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SpriteKit

protocol BattleEnvironmentManagerProtocol: AnyObject {
    var backgroundNode: SKSpriteNode { get }
    func moveBackground(direction: GameDirection)
    func stopBackground()
    func nextBackground()
    func setupEnvironment()
    func update()
}

private extension BattleEnvironmentManager {
    enum Constant {
        static let menuButtonName = "menu_button"
    }
}

class BattleEnvironmentManager: BattleEnvironmentManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    private let menuButton = SKSpriteNode(imageNamed: "menu_button")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var currentGameIndex = 0
    private var backgroundTextures: [SKTexture] = []
    var backgroundNode = SKSpriteNode()

    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func setupEnvironment() {
        setupBackgroundTextures()
        setupBackground()
        setupUI()
    }
    
    private func setupBackgroundTextures() {
        let atlas = SKTextureAtlas(named: "Battle_backgrounds")
        for i in 0..<atlas.textureNames.count {
            backgroundTextures.append(atlas.textureNamed("battle_background_\(i)"))
        }
    }
    
    // MARK: - SETUP FUNCTIONS
    
    func setupBackground() {
        guard let firstFrame = backgroundTextures.first, let scene = scene else { return }
        backgroundNode.texture = firstFrame
        backgroundNode.size = CGSize(width: scene.size.width * 2, height: scene.size.height)
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        backgroundNode.position = CGPoint(
            x: scene.size.width / 2,
            y: 0
        )
        backgroundNode.zPosition = 3
        scene.addChild(backgroundNode)
    }
    
    func nextBackground() {
        currentGameIndex += 1
        guard let newFrame = backgroundTextures[safe: currentGameIndex], let scene = scene else { return }
        backgroundNode.texture = newFrame
    }
    
    func setupUI() {
        guard let scene else { return }
        menuButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.90)
        menuButton.zPosition = 4
        menuButton.size = CGSize(width: 36.0, height: 36.0)
        menuButton.name = Constant.menuButtonName
        scene.addChild(menuButton)
        scene.addChild(scoreLabel)
    }
    
    func update() {
        print("upd")
    }
    
    func moveBackground(direction: GameDirection) {
        guard let scene = scene else { return }
        
        for node in scene.children {
            if node == backgroundNode {
                let moveAction = SKAction.moveBy(x: direction == .left ? 100 : -100, y: 0, duration: 1.0)
                let repeatAction = SKAction.repeatForever(moveAction)
                
                if node.action(forKey: GameConstant.backgroundAction) == nil {
                    node.run(repeatAction, withKey: GameConstant.backgroundAction)
                }
            }
        }
    }
    
    func stopBackground() {
        guard let scene = scene else { return }
        for node in scene.children {
            node.removeAction(forKey: GameConstant.backgroundAction)
        }
    }
}
