//
//  GameScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SpriteKit
import SwiftUI
import AVFoundation

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

    override func didMove(to view: SKView) {
        background.color = .backgroundSystem
        physicsWorld.contactDelegate = self // enableds collision dection
        setupBackground()
        setupUI()
        setupTree()
        setupWalkTextures() // Yeni: Walk.png'den tekstürleri ayır
        setupPlayer()
        startGame()
    }
    
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
        /*
        let textureName = "men_walk_3"
        let texture = atlas.textureNamed(textureName)
        frames.append(texture)
        let textureName1 = "men_walk_4"
        let texture1 = atlas.textureNamed(textureName1)
        frames.append(texture1)
         */
        /*
        currentIndex -= 1
        
        while currentIndex > 0 {
            let textureName = "men_walk_\(i)"
            let texture = atlas.textureNamed(textureName)
            frames.append(texture)
        }
         */
        walkTextures = frames
    }

    private func setupPlayer() {
        guard let firstFrame = walkTextures.first else {
                print("walkTextures is empty, player cannot be created")
                return
            }
        
        playerSprite.texture = firstFrame
        playerSprite.size = firstFrame.size()
        playerSprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        playerSprite.position = CGPoint(
            x: self.size.width / 2,
            y: floor.size.height * 0.8
        )
        
        playerSprite.zPosition = 3
        addChild(playerSprite)
        
        
        let walkAction = SKAction.animate(
            with: walkTextures,
            timePerFrame: 0.1,
            resize: false,
            restore: false
        )
        
        let foreverWalk = SKAction.repeatForever(walkAction)
        playerSprite.run(foreverWalk, withKey: "walkingAnimation")
         
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
}

