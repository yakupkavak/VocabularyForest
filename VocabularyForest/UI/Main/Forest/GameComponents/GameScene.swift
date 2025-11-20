//
//  GameScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SpriteKit
import SwiftUI
import AVFoundation

extension GameScene {
    enum Constant {
        static let movingCharacterAnimation = "movingCharacterAnimation"
        static let movingCharacterAction = "movingCharacterAction"
        static let backgroundAction = "backgroundAnimation"
        static let airAction = "airAnimation"
        static let movingDistance: CGFloat = 100
        static let movingTimePerFrame: CGFloat = 0.1
        static let gameWidthSize = UIScreen.main.bounds.width * CGFloat(4)
        static let gameHeightSize = UIScreen.main.bounds.height
    }
    enum GameDirection {
        case right
        case left
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - PROPERTIES
     
    var walkTextures: [SKTexture] = []
    let playerSprite = SKSpriteNode()
    var skyDecor = SKSpriteNode(imageNamed: "sky_decor")
    var floor = SKSpriteNode(imageNamed: "floor_cropped")
    let tree = SKSpriteNode(imageNamed: "firstTree")
    var scoreLabel = SKLabelNode(fontNamed: "AevnirNext-Bold")
    var score = 0
    var gameOver = false
    var gameTimer: Timer?
    var scoreTimer: Timer?
    var characterDirection: GameDirection = .right
    var characterMovingActive = false
    var isTouching = false

    // MARK: - OVERRIDE FUNCTIONS
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self // enableds collision dection
        setupBackground()
        setupUI()
        setupTree()
        setupWalkTextures()
        startGame()
        moveSky()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isTouching else { return }
        let centerScreen = self.size.width / 2
        let halfPlayerWidth = playerSprite.size.width / 2
        if characterMovingActive {
            if characterDirection == .left && playerSprite.position.x <= centerScreen {
                if floor.frame.minX < 0 {
                    switchToBackgroundMode(direction: .left)
                    return
                }
            }
            if characterDirection == .right && playerSprite.position.x >= centerScreen {
                if floor.frame.maxX > self.size.width {
                    switchToBackgroundMode(direction: .right)
                    return
                }
            }
        }
        if floor.frame.maxX <= self.size.width {
            if characterDirection == .right {
                if playerSprite.position.x >= self.size.width - halfPlayerWidth {
                    // Evet dayandı: İlerlemeyi durdur (Ayaklar çalışmaya devam eder)
                    playerSprite.removeAction(forKey: Constant.movingCharacterAction)
                    characterMovingActive = false
                }
                else if !characterMovingActive {
                    stopBackgroundMoving()
                    characterMovingAction(direction: .right)
                    characterMovingActive = true
                }
            }
        }
        else if floor.frame.minX >= 0 {
            if characterDirection == .left {
                if playerSprite.position.x <= halfPlayerWidth {
                    playerSprite.removeAction(forKey: Constant.movingCharacterAction)
                    characterMovingActive = false
                }
                else if !characterMovingActive {
                    stopBackgroundMoving()
                    characterMovingAction(direction: .left)
                    characterMovingActive = true
                }
            }
        }
        checkInfinitySky()
    }
    
    // MARK: - PRIVATE HELPERS
    
    private func setupWalkTextures() {
        let atlas = SKTextureAtlas(named: "MenWalking")
        var frames: [SKTexture] = []
        var currentIndex = 0
        while currentIndex < atlas.textureNames.count {
            let textureName = "men_walk_\(currentIndex)"
            let texture = atlas.textureNamed(textureName)
            frames.append(texture)
            currentIndex += 1
        }
        walkTextures = frames
        setupPlayer()
    }
    
    private func stopBackgroundMoving() {
        for node in children {
            if let sprite = node as? SKSpriteNode, sprite != playerSprite {
                sprite.removeAction(forKey: Constant.backgroundAction)
            }
        }
    }
     
    private func stopAllMoving() {
        characterMovingActive = false
        playerSprite.removeAction(forKey: Constant.movingCharacterAnimation)
        playerSprite.removeAction(forKey: Constant.movingCharacterAction)
        for node in children {
            if let sprite = node as? SKSpriteNode, sprite != playerSprite {
                sprite.removeAction(forKey: Constant.backgroundAction)
            }
        }
    }

    private func setupPlayer() {
        guard let firstFrame = walkTextures.first else { return }
        
        playerSprite.texture = firstFrame
        playerSprite.size = firstFrame.size()
        playerSprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        playerSprite.position = CGPoint(
            x: self.size.width / 2,
            y: floor.size.height * 0.7
        )
        playerSprite.zPosition = 3
        addChild(playerSprite)
    }
    
    private func startGame(){
        gameTimer?.invalidate()
        scoreTimer?.invalidate()
        
    }
    
    private func setupBackground() {
        for i in 0..<2{
            let backDecor = SKSpriteNode(imageNamed: "back_decor")
            let middleDecor = SKSpriteNode(imageNamed: "middle_decor")
            backDecor.size.width = Constant.gameWidthSize
            backDecor.size.height = Constant.gameHeightSize
            backDecor.position = CGPoint(x: size.width / 2 + (CGFloat(i) * Constant.gameWidthSize), y: size.height / 2)
            backDecor.name = "clouds"
            backDecor.zPosition = -2
            addChild(backDecor)
            middleDecor.size.width = Constant.gameWidthSize
            middleDecor.size.height = Constant.gameHeightSize
            middleDecor.name = "clouds"
            middleDecor.position = CGPoint(x: size.width / 2 + (CGFloat(i) * Constant.gameWidthSize), y: size.height / 2)
            middleDecor.zPosition = -1
            addChild(middleDecor)
        }
        skyDecor.size.width = Constant.gameWidthSize
        skyDecor.size.height = Constant.gameHeightSize
        skyDecor.position = CGPoint(x: size.width / 2, y: size.height / 2)
        skyDecor.zPosition = -3
        addChild(skyDecor)
        floor.position = CGPoint(x: size.width / 2, y: 0)
        floor.size.width = Constant.gameWidthSize
        floor.size.height = 120
        floor.zPosition = 1
        floor.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(floor)
    }
    
    private func setupUI() {
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        addChild(scoreLabel)
    }
    
    private func setupTree() {
        tree.anchorPoint = CGPoint(x: 0.5, y: 0)
        tree.position = CGPoint(
                    x: self.size.width / 3,
                    y: floor.size.height * 0.3
                )
        tree.zPosition = 0
        addChild(tree)
    }
    
    // MARK: - CHARACTER MOVING FUNCTIONS
    
    private func startMovementLogic(direction: GameDirection) {
        if direction == .right {
            rightMovingAnimation()
        } else {
            leftMovingAnimation()
        }
        
        if direction == .right {
            //Sağ tarafın sonuna geldik mi
            if floor.frame.maxX <= self.size.width {
                characterMovingAction(direction: .right)
                characterMovingActive = true
            }else if floor.frame.minX >= 0 {
                characterMovingAction(direction: .left)
                characterMovingActive = true
            }
            else {
                moveBackground(direction: .right)
                characterMovingActive = false
            }
        }
        else {
            // Sol tarafın sonuna geldik mi
            if floor.frame.minX >= 0 {
                characterMovingAction(direction: .left)
                characterMovingActive = true
            }else if floor.frame.maxX <= self.size.width{
                characterMovingAction(direction: .left)
                characterMovingActive = true
            }
            else {
                moveBackground(direction: .left)
                characterMovingActive = false
            }
        }
    }
    
    private func characterMovingAction(direction: GameDirection) {
        let moveAction = SKAction.moveBy(x: direction == .right ? 100 : -100, y: 0, duration: 1.0)
        let repeatAction = SKAction.repeatForever(moveAction)
        playerSprite.run(repeatAction, withKey: Constant.movingCharacterAction)
    }
    
    private func leftMovingAnimation() {
        characterDirection = .left
        if playerSprite.action(forKey: Constant.movingCharacterAnimation) != nil {
            return
        }
        playerSprite.xScale = -1.0
        let walkAction = SKAction.animateSprite(
            textures: walkTextures,
            timePerFrame: Constant.movingTimePerFrame
        )
        let foreverWalkAction = SKAction.repeatForever(walkAction)
        playerSprite.run(foreverWalkAction, withKey: Constant.movingCharacterAnimation)
    }
    
    private func rightMovingAnimation() {
        characterDirection = .right
        if playerSprite.action(forKey: Constant.movingCharacterAnimation) != nil {
            return
        }
        let walkAction = SKAction.animateSprite(
            textures: walkTextures,
            timePerFrame: Constant.movingTimePerFrame
        )
        playerSprite.xScale = 1.0
        let foreverWalkAction = SKAction.repeatForever(walkAction)
        playerSprite.run(foreverWalkAction, withKey: Constant.movingCharacterAnimation)
    }
    
    // MARK: - BACKGROUND FUNCTIONS
    
    private func moveSky(){
        enumerateChildNodes(withName: "clouds") { node, _ in
            let sky = node as! SKSpriteNode
            let moveAction = SKAction.moveBy(x: -10, y: 0, duration: 1.0)
            let repeatAction = SKAction.repeatForever(moveAction)
            sky.run(repeatAction, withKey: Constant.airAction)
        }
    }
    
    private func checkInfinitySky() {
        enumerateChildNodes(withName: "clouds") { node, _ in
            let sky = node as! SKSpriteNode
            let skyWidth = sky.size.width
            if sky.position.x <= -skyWidth / 2 {
                sky.position.x += skyWidth * 2
            }
            if sky.position.x >= self.size.width + skyWidth / 2 {
                sky.position.x -= skyWidth * 2
            }
        }
    }
    
    private func switchToBackgroundMode(direction: GameDirection) {
        playerSprite.removeAction(forKey: Constant.movingCharacterAction)
        playerSprite.position.x = self.size.width / 2
        characterMovingActive = false
        moveBackground(direction: direction)
    }
        
    private func moveBackground(direction: GameDirection) {
        for node in children {
            if let sprite = node as? SKSpriteNode, sprite != playerSprite {
                let moveAction = SKAction.moveBy(x: direction.self == .left ? 100 : -100, y: 0, duration: 1.0)
                let repeatAction = SKAction.repeatForever(moveAction)
                sprite.run(repeatAction, withKey: Constant.backgroundAction)
            }
        }
    }

    // MARK: - TOUCH EVENTS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = true
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        if touchLocation.x > self.size.width / 2 {
            startMovementLogic(direction: .right)
        } else {
            startMovementLogic(direction: .left)
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        stopAllMoving()
    }
}

