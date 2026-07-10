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
    func moveBackground(direction: HorizontalDirection)
    func stopBackground()
    func update()
    func startRain()
    func stopRain()
    func startDrought()
    func finishDrought()
    func showPositionArrows()
    func closePositionArrows()
}

private extension EnvironmentManager {
    enum Constant {
        static let menuButtonName = "menu_button"
    }
}
class EnvironmentManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let floorNode = SKSpriteNode(imageNamed: "floor")
    private var skyDecor = SKSpriteNode(imageNamed: "sky_decor")
    private let waterStatue = SKSpriteNode(imageNamed: "water_statue")
    private let grassStatue = SKSpriteNode(imageNamed: "grass_statue")
    private let menuButton = SKSpriteNode(imageNamed: "menu_button")
    private let announcementButton = SKSpriteNode(imageNamed: "announcement_button")
    private let forestButton = SKSpriteNode(imageNamed: "forest_button")
    private let marketButton = SKSpriteNode(imageNamed: "market_button")
    private let playButton = SKSpriteNode(imageNamed: "play_button")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let rightIcon = SKSpriteNode(imageNamed: "right_icon")
    private let leftIcon = SKSpriteNode(imageNamed: "left_icon")
    private let downIcon = SKSpriteNode(imageNamed: "down_icon")
    private let upIcon = SKSpriteNode(imageNamed: "up_icon")
    private let confirmIcon = SKSpriteNode(imageNamed: "accept_button")
    private let refuseIcon = SKSpriteNode(imageNamed: "close_button")
    private var icons: [SKSpriteNode] = []

    private var isRaining = false
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
        icons = [rightIcon, leftIcon, upIcon, downIcon, confirmIcon, refuseIcon]
    }
}

// MARK: - PRIVATE HELPERS

private extension EnvironmentManager {
    
    func setupBackgroundDecor() {
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
    
    func setupRainDecor() {
        guard let scene else { return }
        for i in 0...3 {
            let rain = SKSpriteNode(imageNamed: "rain_0")
            rain.size = CGSize(width: scene.size.width, height: GameConstant.gameHeightSize / 2)
            rain.anchorPoint = CGPoint(x: 0.5, y: 0)
            rain.position = CGPoint(x: scene.size.width / 2, y: GameConstant.gameHeightSize + CGFloat(i) * GameConstant.gameHeightSize / 2)
            rain.zPosition = 5
            rain.name = "rain"
            rain.isHidden = true
            scene.addChild(rain)
        }
    }
    
    func startRainAnimation() {
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            let sky = node as! SKSpriteNode
            let moveAction = SKAction.moveBy(x: 0, y: -100, duration: 1.0)
            let repeatAction = SKAction.repeatForever(moveAction)
            sky.run(repeatAction, withKey: GameConstant.rainAnimation)
        }
    }
    
    func setupFloor() {
        guard let scene else { return }
        floorNode.position = CGPoint(x: scene.size.width / 2, y: 0)
        floorNode.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.floorHeightSize)
        floorNode.zPosition = 1
        floorNode.name = ForestConstant.floorName
        floorNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        scene.addChild(floorNode)
    }
    
    func moveSky(){
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "clouds") { node, _ in
            let sky = node as! SKSpriteNode
            let moveAction = SKAction.moveBy(x: -10, y: 0, duration: 1.0)
            let repeatAction = SKAction.repeatForever(moveAction)
            sky.run(repeatAction, withKey: GameConstant.airAction)
        }
    }
    
    func checkRain() {
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            let rain = node as! SKSpriteNode
            if rain.position.y + rain.bounds.height <= 0 {
                rain.position.y = GameConstant.gameHeightSize
            }
        }
    }

    func checkInfinitySky() {
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
}

extension EnvironmentManager: EnvironmentManagerProtocol {

    func setupEnvironment() {
        setupSky()
        setupBackgroundDecor()
        setupRainDecor()
        setupFloor()
        setupUI()
        moveSky()
    }
    
    // MARK: - SETUP FUNCTIONS
    
    func setupUI() {
        guard let scene else { return }
        scoreLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 80)
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        menuButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.90)
        menuButton.zPosition = 4
        menuButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        menuButton.name = Constant.menuButtonName
        announcementButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.83)
        announcementButton.zPosition = 4
        announcementButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        announcementButton.name = "announcementButton"
        playButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.76)
        playButton.zPosition = 4
        playButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        playButton.name = "play_button"
        forestButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.69)
        forestButton.zPosition = 4
        forestButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        forestButton.name = "forest_button"
        marketButton.position = CGPoint(x: scene.size.width * 0.90, y: scene.size.height * 0.62)
        marketButton.zPosition = 4
        marketButton.size = CGSize(width: scene.size.height * 0.05, height: scene.size.height * 0.05)
        marketButton.name = "market_button"
        rightIcon.name = ForestConstant.rightIconName
        leftIcon.name = ForestConstant.leftIconName
        downIcon.name = ForestConstant.downIconName
        upIcon.name = ForestConstant.upIconName
        confirmIcon.name = ForestConstant.confirmIconName
        refuseIcon.name = ForestConstant.refuseIconName
        scene.addChild(forestButton)
        scene.addChild(playButton)
        scene.addChild(announcementButton)
        scene.addChild(menuButton)
        scene.addChild(marketButton)
        scene.addChild(scoreLabel)
    }
    
    func setupSky() {
        guard let scene = scene else { return }
        skyDecor.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.gameHeightSize)
        skyDecor.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        skyDecor.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        skyDecor.zPosition = -4
        scene.addChild(skyDecor)
    }
    
    // MARK: - MOVEMENT LOGIC
    
    func moveBackground(direction: HorizontalDirection) {
        guard let scene = scene else { return }
        
        for node in scene.children {
            if node == floorNode || node == waterStatue || node == grassStatue || node.name == "Animal" || node.name == "sculpture" || node.name == "plant" {
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
        checkInfinitySky()
        if isRaining {
            checkRain()
        }
    }
    
    func startRain() {
        guard let scene else { return }
        isRaining = true
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            let rain = node as! SKSpriteNode
            rain.isHidden = false
        }
        startRainAnimation()
    }
    
    func stopRain() {
        guard let scene else { return }
        isRaining = false
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            node.removeAction(forKey: GameConstant.rainAnimation)
            node.isHidden = true
        }
    }
    
    func startDrought() {
        floorNode.color = .brown
        floorNode.colorBlendFactor = 0.8
    }

    func finishDrought() {
        floorNode.colorBlendFactor = 0.0
    }
    
    // MARK: - POSITION UPDATE
    
    func showPositionArrows() {
        guard let scene else { return }
        if rightIcon.parent != nil || icons.isEmpty {
            return
        }
        rightIcon.position = CGPoint(x: scene.size.width * 0.65, y: scene.size.height * 0.6)
        leftIcon.position = CGPoint(x: scene.size.width * 0.35, y: scene.size.height * 0.6)
        upIcon.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.67)
        downIcon.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.53)
        confirmIcon.position = CGPoint(x: scene.size.width * 0.75, y: scene.size.height * 0.48)
        refuseIcon.position = CGPoint(x: scene.size.width * 0.25, y: scene.size.height * 0.48)
        for icon in icons {
            let iconSize = scene.size.width * 0.15
            icon.size = CGSize(width: iconSize, height: iconSize)
            icon.zPosition = 10.0
            icon.anchorPoint = CGPoint(x: 0.5, y: 0)
            scene.addChild(icon)
        }
    }
    
    func closePositionArrows() {
        for icon in icons {
            icon.removeFromParent()
        }
    }
}
