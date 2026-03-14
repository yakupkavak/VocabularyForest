// MARK: - PlayerManager.swift

//
//  PlayerManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import SpriteKit

protocol PlayerManagerProtocol: AnyObject {
    var playerNode: SKSpriteNode { get }
    var direction: HorizontalDirection { get }
    var isMoving: Bool { get }
    func setupPlayer()
    func startWalking(direction: HorizontalDirection)
    func startWaiting()
    func stopWalking()
    func stopPhysicalMovement()
}

// MARK: - CONSTANTS

extension PlayerManager {
    enum Constants {
        static let zero: CGFloat = 0.0
        static let startIndex: Int = 0
        
        static let anchorPointX: CGFloat = 0.5
        static let anchorPointY: CGFloat = 0.0
        static let screenWidthDivider: CGFloat = 2.0
        static let floorHeightMultiplier: CGFloat = 0.83
        static let defaultZPosition: CGFloat = 2.0
        
        static let scaleRight: CGFloat = 1.0
        static let scaleLeft: CGFloat = -1.0
        
        static let waitingTimeMultiplier: Double = 1.3
        
        static let moveAmountRight: CGFloat = 100.0
        static let moveAmountLeft: CGFloat = -100.0
        static let moveDuration: TimeInterval = 1.0
    }
}

class PlayerManager: PlayerManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let playerNode = SKSpriteNode()
    private var walkTextures: [SKTexture] = []
    private var idleTextures: [SKTexture] = []
    var direction: HorizontalDirection = .right
    var isMoving: Bool = false
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
        setupWalkTextures()
        setupIdleTextures()
    }
    
    // MARK: - SETUP
    
    private func setupWalkTextures() {
        let atlas = SKTextureAtlas(named: "MenWalking")
        for i in Constants.startIndex..<atlas.textureNames.count {
            walkTextures.append(atlas.textureNamed("men_walk_\(i)"))
        }
    }
    
    private func setupIdleTextures() {
        let atlas = SKTextureAtlas(named: "MenIdle")
        for i in Constants.startIndex..<atlas.textureNames.count {
            idleTextures.append(atlas.textureNamed("men_idle_\(i)"))
        }
    }
    
    func setupPlayer() {
        guard let firstFrame = walkTextures.first, let scene = scene else { return }
        
        playerNode.texture = firstFrame
        playerNode.size = firstFrame.size()
        playerNode.anchorPoint = CGPoint(x: Constants.anchorPointX, y: Constants.anchorPointY)
        playerNode.position = CGPoint(
            x: scene.size.width / Constants.screenWidthDivider,
            y: GameConstant.floorHeightSize * Constants.floorHeightMultiplier
        )
        playerNode.zPosition = Constants.defaultZPosition
        
        startWaiting()
        scene.addChild(playerNode)
    }
    
    // MARK: - ACTIONS
    
    func startWaiting() {
        stopPhysicalMovement()
        playerNode.removeAction(forKey: GameConstant.movingCharacterAnimation)
        self.isMoving = false
        playerNode.xScale = (direction == .right) ? Constants.scaleRight : Constants.scaleLeft
        if playerNode.action(forKey: GameConstant.waitingCharacterAnimation) == nil {
            let animate = SKAction.animate(with: idleTextures, timePerFrame: GameConstant.waitingTimePerFrame * Constants.waitingTimeMultiplier)
            playerNode.run(SKAction.repeatForever(animate), withKey: GameConstant.waitingCharacterAnimation)
        }
    }
    
    func stopWaiting() {
        playerNode.removeAction(forKey: GameConstant.waitingCharacterAnimation)
    }
    
    func startWalking(direction: HorizontalDirection) {
        stopWaiting()
        self.direction = direction
        self.isMoving = true
        playerNode.xScale = (direction == .right) ? Constants.scaleRight : Constants.scaleLeft
        if playerNode.action(forKey: GameConstant.movingCharacterAnimation) == nil {
            let animate = SKAction.animate(with: walkTextures, timePerFrame: GameConstant.movingTimePerFrame)
            playerNode.run(SKAction.repeatForever(animate), withKey: GameConstant.movingCharacterAnimation)
        }
        movePlayerNode(direction: direction)
    }
    
    private func movePlayerNode(direction: HorizontalDirection) {
        let moveAmount: CGFloat = (direction == .right) ? Constants.moveAmountRight : Constants.moveAmountLeft
        let moveAction = SKAction.moveBy(x: moveAmount, y: Constants.zero, duration: Constants.moveDuration)
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
        startWaiting()
    }
}
