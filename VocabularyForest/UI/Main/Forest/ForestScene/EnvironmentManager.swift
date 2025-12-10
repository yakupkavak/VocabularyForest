//
//  EnvironmentManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import SpriteKit

protocol EnvironmentManagerProtocol: AnyObject {
    var floorNode: SKSpriteNode { get }
    func setupEnvironment()
    func moveBackground(direction: GameDirection)
    func stopBackground()
    func update()
}

private extension EnvironmentManager {
    enum Constant {
        static let menuButtonName = "menu_button"
    }
}
class EnvironmentManager: EnvironmentManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let floorNode = SKSpriteNode(imageNamed: "floor")
    private var skyDecor = SKSpriteNode(imageNamed: "sky_decor")
    private let waterStatue = SKSpriteNode(imageNamed: "water_statue")
    private let grassStatue = SKSpriteNode(imageNamed: "grass_statue")
    private let menuButton = SKSpriteNode(imageNamed: "menu_button")
    private let questButton = SKSpriteNode(imageNamed: "quest_button")
    private let playButton = SKSpriteNode(imageNamed: "play_button")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func setupEnvironment() {
        setupSky()
        setupBackgroundDecor()
        setupFloor()
        setupUI()
        moveSky()
    }
    
    // MARK: - SETUP FUNCTIONS
    
    func setupUI() {
        guard let scene else { return }
        waterStatue.anchorPoint = CGPoint(x: 0.5, y: 0)
        waterStatue.position = CGPoint(x: GameConstant.gameWidthSize * -0.15, y: 0)
        waterStatue.zPosition = 4
        scene.addChild(waterStatue)
        grassStatue.anchorPoint = CGPoint(x: 0.5, y: 0)
        grassStatue.position = CGPoint(x: GameConstant.gameWidthSize * 0.15, y: 10)
        grassStatue.zPosition = 4
        scene.addChild(grassStatue)
        scoreLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 80)
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        menuButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.90)
        menuButton.zPosition = 4
        menuButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        menuButton.name = Constant.menuButtonName
        questButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.83)
        questButton.zPosition = 4
        questButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        questButton.name = "quest_button"
        playButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.76)
        playButton.zPosition = 4
        playButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        playButton.name = "play_button"
        scene.addChild(playButton)
        scene.addChild(questButton)
        scene.addChild(menuButton)
        scene.addChild(scoreLabel)
    }
    
    private func setupBackgroundDecor() {
        guard let scene else { return }
        for i in 0..<2 {
            let backDecor = SKSpriteNode(imageNamed: "back_decor")
            let middleDecor = SKSpriteNode(imageNamed: "middle_decor")
            
            backDecor.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.gameHeightSize)
            backDecor.position = CGPoint(x: scene.size.width / 2 + (CGFloat(i) * GameConstant.gameWidthSize), y: scene.size.height * 0.75)

            backDecor.zPosition = -3
            backDecor.name = "clouds"
            scene.addChild(backDecor)
            
            middleDecor.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.gameHeightSize)
            middleDecor.position = CGPoint(x: scene.size.width / 2 + (CGFloat(i) * GameConstant.gameWidthSize), y: scene.size.height / 2)
            middleDecor.zPosition = -2
            middleDecor.name = "clouds"
            scene.addChild(middleDecor)
        }
    }
    
    func setupSky() {
        guard let scene = scene else { return }
        skyDecor.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.gameHeightSize)
        skyDecor.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        skyDecor.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        skyDecor.zPosition = -4
        scene.addChild(skyDecor)
    }
    
    private func setupFloor() {
        guard let scene else { return }
        floorNode.position = CGPoint(x: scene.size.width / 2, y: 0)
        floorNode.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.floorHeightSize)
        floorNode.zPosition = 1
        floorNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        scene.addChild(floorNode)
    }
    
    private func moveSky(){
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "clouds") { node, _ in
            let sky = node as! SKSpriteNode
            let moveAction = SKAction.moveBy(x: -10, y: 0, duration: 1.0)
            let repeatAction = SKAction.repeatForever(moveAction)
            sky.run(repeatAction, withKey: GameConstant.airAction)
        }
    }

    private func checkInfinitySky() {
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "clouds") { node, _ in
            let sky = node as! SKSpriteNode
            let skyWidth = sky.size.width
            if sky.position.x <= -skyWidth / 2 {
                sky.position.x += skyWidth * 2
            }
            if sky.position.x >= scene.size.width + skyWidth / 2 {
                sky.position.x -= skyWidth * 2
            }
        }
    }
    
    // MARK: - MOVEMENT LOGIC
    
    func moveBackground(direction: GameDirection) {
        guard let scene = scene else { return }
        
        for node in scene.children {
            if node == floorNode || node == waterStatue || node == grassStatue || node.name == "Animal" {
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
    
    func update() {
        guard let scene else { return }
        checkInfinitySky()
    }
}
