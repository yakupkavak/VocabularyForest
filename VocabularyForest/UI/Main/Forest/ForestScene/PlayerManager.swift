//
//  PlayerManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import SpriteKit

protocol PlayerManagerProtocol: AnyObject {
    var playerNode: SKSpriteNode { get }
    var direction: GameDirection { get }
    var isMoving: Bool { get }
    func setupPlayer()
    func startWalking(direction: GameDirection)
    func stopWalking()
    func stopPhysicalMovement()
}

class PlayerManager: PlayerManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let playerNode = SKSpriteNode()
    private var walkTextures: [SKTexture] = []
    var direction: GameDirection = .right
    var isMoving: Bool = false
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
        setupWalkTextures()
    }
    
    // MARK: - SETUP
    
    private func setupWalkTextures() {
        let atlas = SKTextureAtlas(named: "MenWalking")
        for i in 0..<atlas.textureNames.count {
            walkTextures.append(atlas.textureNamed("men_walk_\(i)"))
        }
    }
    
    func setupPlayer() {
        guard let firstFrame = walkTextures.first, let scene = scene else { return }
        
        playerNode.texture = firstFrame
        playerNode.size = firstFrame.size()
        playerNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        playerNode.position = CGPoint(
            x: scene.size.width / 2,
            y: GameConstant.floorHeightSize * 0.83
        )
        playerNode.zPosition = 3
        scene.addChild(playerNode)
    }
    
    // MARK: - ACTIONS
    
    func startWalking(direction: GameDirection) {
        self.direction = direction
        self.isMoving = true
        playerNode.xScale = (direction == .right) ? 1.0 : -1.0
        if playerNode.action(forKey: GameConstant.movingCharacterAnimation) == nil {
            let animate = SKAction.animate(with: walkTextures, timePerFrame: GameConstant.movingTimePerFrame)
            playerNode.run(SKAction.repeatForever(animate), withKey: GameConstant.movingCharacterAnimation)
        }
        movePlayerNode(direction: direction)
    }
    
    private func movePlayerNode(direction: GameDirection) {
        let moveAmount: CGFloat = (direction == .right) ? 100 : -100
        let moveAction = SKAction.moveBy(x: moveAmount, y: 0, duration: 1.0)
        let repeatAction = SKAction.repeatForever(moveAction)
        
        if playerNode.action(forKey: GameConstant.movingCharacterAction) == nil {
            playerNode.run(repeatAction, withKey: GameConstant.movingCharacterAction)
        }
    }
    
    func stopPhysicalMovement() {
        playerNode.removeAction(forKey: GameConstant.movingCharacterAction)
    }
    
    func stopWalking() {
        isMoving = false
        playerNode.removeAction(forKey: GameConstant.movingCharacterAnimation)
        playerNode.removeAction(forKey: GameConstant.movingCharacterAction)
    }
}
