//
//  GamePlayerManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.11.2025.
//

import SpriteKit

protocol GamePlayerManagerProtocol: AnyObject {
    var playerNode: SKSpriteNode { get }
    var direction: GameDirection { get }
    var isMoving: Bool { get }
    func setupPlayer()
    func startWalking(direction: GameDirection)
    func startWaiting()
    func stopWalking()
    func stopPhysicalMovement()
    func die(completion: @escaping () -> Void)
    func startAttack(completion: @escaping () -> Void)
}

class GamePlayerManager: GamePlayerManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let playerNode = SKSpriteNode()
    private var attackTextures: [SKTexture] = []
    private var walkTextures: [SKTexture] = []
    private var idleTextures: [SKTexture] = []
    private var dieTextures: [SKTexture] = []
    var direction: GameDirection = .right
    var isMoving: Bool = false
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
        setupWalkTextures()
        setupIdleTextures()
        setupAttackTextures()
        setupDieTextures()
    }
    
    // MARK: - SETUP
    
    private func setupAttackTextures() {
        let atlas = SKTextureAtlas(named: "MenAttack")
        for i in 0..<atlas.textureNames.count {
            attackTextures.append(atlas.textureNamed("men_attack_\(i)"))
        }
    }
    
    private func setupDieTextures() {
        let atlas = SKTextureAtlas(named: "MenDie")
        for i in 0..<atlas.textureNames.count {
            dieTextures.append(atlas.textureNamed("men_die_\(i)"))
        }
    }
    
    private func setupWalkTextures() {
        let atlas = SKTextureAtlas(named: "MenWalking")
        for i in 0..<atlas.textureNames.count {
            walkTextures.append(atlas.textureNamed("men_walk_\(i)"))
        }
    }
    
    private func setupIdleTextures() {
        let atlas = SKTextureAtlas(named: "MenIdle")
        for i in 0..<atlas.textureNames.count {
            idleTextures.append(atlas.textureNamed("men_idle_\(i)"))
        }
    }
    
    func setupPlayer() {
        guard let firstFrame = walkTextures.first, let scene = scene else { return }
        playerNode.texture = firstFrame
        playerNode.size = firstFrame.size()
        playerNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        playerNode.position = CGPoint(
            x: scene.size.width * 0.2,
            y: BattleConstant.characterPosition
        )
        playerNode.zPosition = 3
        scene.addChild(playerNode)
    }
    
    // MARK: - ACTIONS
    
    func startAttack(completion: @escaping () -> Void) {
        stopWalking()
        let animate = SKAction.animate(with: attackTextures, timePerFrame: 0.2)
        let completion = SKAction.run {
            completion()
        }
        playerNode.run(SKAction.sequence([animate,completion]), withKey: GameConstant.attackAnimation)
    }
    
    func startWaiting() {
        stopWalking()
        self.isMoving = false
        playerNode.xScale = (direction == .right) ? 1.0 : -1.0
        if playerNode.action(forKey: GameConstant.waitingCharacterAnimation) == nil {
            let animate = SKAction.animate(with: idleTextures, timePerFrame: GameConstant.waitingTimePerFrame)
            playerNode.run(SKAction.repeatForever(animate), withKey: GameConstant.waitingCharacterAnimation)
        }
    }
    
    func stopWaiting() {
        playerNode.removeAction(forKey: GameConstant.waitingCharacterAnimation)
    }
    
    func startWalking(direction: GameDirection) {
        stopWaiting()
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
    
    func die(completion: @escaping () -> Void) {
        playerNode.removeAllActions()
        let animate = SKAction.animate(with: dieTextures, timePerFrame: GameConstant.dyingTimePerFrame, resize: false, restore: false)
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let dieAction = SKAction.run { [weak self] in
            guard let self else { return }
            playerNode.removeFromParent()
            completion()
        }
        let diePosition = SKAction.run { [weak self] in
            guard let self else { return }
            playerNode.texture = dieTextures.last
        }
        playerNode.run(SKAction.sequence([animate,diePosition, fadeOut, dieAction]))
    }
}
