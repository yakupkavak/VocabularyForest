//
//  GameScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SpriteKit
import SwiftUI
import AVFoundation

private extension GameScene {
    enum Constant {
        static let movingAction = "walkingAnimation"
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - PROPERTIES
     
    var walkTextures: [SKTexture] = []
    let playerSprite = SKSpriteNode()
    var background = SKSpriteNode(imageNamed: "background_forest")
    var floor = SKSpriteNode(imageNamed: "floor_cropped")
    let tree = SKSpriteNode(imageNamed: "firstTree")
    var scoreLabel = SKLabelNode(fontNamed: "AevnirNext-Bold")
    var score = 0
    var gameOver = false
    var gameTimer: Timer? //control the enemy spawning and movement
    var scoreTimer: Timer? // update every second for the score

    // MARK: - OVERRIDE FUNCTIONS
    
    override func didMove(to view: SKView) {
        background.color = .backgroundSystem
        physicsWorld.contactDelegate = self // enableds collision dection
        setupBackground()
        setupUI()
        setupTree()
        setupWalkTextures()
        startGame()
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
        setupWalkPlayer()
    }
    
    private func leftMoving() {
        if playerSprite.action(forKey: Constant.movingAction) != nil {
            return
        }
        playerSprite.xScale = -1.0
        let walkAction = SKAction.animate(
            with: walkTextures,
            timePerFrame: 0.1,
            resize: false,
            restore: false
        )
        let foreverWalkAction = SKAction.repeatForever(walkAction)
        let moveLeft = SKAction.moveBy(x: -100, y: 0, duration: 1.0)
        let foreverWalkMove = SKAction.repeatForever(moveLeft)
        let walkingAnimationGroup = SKAction.group([foreverWalkAction, foreverWalkMove])
        playerSprite.run(walkingAnimationGroup, withKey: Constant.movingAction)
    }
    
    private func rightMoving() {
        if playerSprite.action(forKey: Constant.movingAction) != nil {
            return
        }
        let walkAction = SKAction.animate(
            with: walkTextures,
            timePerFrame: 0.1,
            resize: false,
            restore: false
        )
        playerSprite.xScale = 1.0
        let foreverWalkAction = SKAction.repeatForever(walkAction)
        let moveRight = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        let foreverWalkMove = SKAction.repeatForever(moveRight)
        let walkingAnimationGroup = SKAction.group([foreverWalkAction, foreverWalkMove])
        playerSprite.run(walkingAnimationGroup, withKey: Constant.movingAction)
    }
     
    private func stopMoving() {
        playerSprite.removeAction(forKey: Constant.movingAction)
    }

    private func setupWalkPlayer() {
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
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true){ _ in
            //self.score += 1
            self.moveBackground()
            //self.updateScoreLabel()
        }
    }
    
    private func setupBackground() {
        background.size = self.size
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        addChild(background)
        floor.position = CGPoint(x: size.width / 2, y: 0)
        floor.size.width = self.size.width
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
        updateScoreLabel()
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
    
    func moveBackground() {
        for node in children {
            if let sprite = node as? SKSpriteNode, sprite != background, sprite != floor, sprite != playerSprite {
                sprite.position.x -= 1
                if sprite.position.x < 0 - sprite.size.width {
                    sprite.removeFromParent()
                }
            }
        }
    }
    
    func updateScoreLabel(){
        scoreLabel.text = "Timer Surived: \(score) "
    }
    
    // MARK: - TOUCH EVENTS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        if touchLocation.x > self.size.width / 2 {
            rightMoving()
        } else {
            leftMoving()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopMoving()
    }
}

