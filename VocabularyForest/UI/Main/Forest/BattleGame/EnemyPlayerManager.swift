//
//  EnemyPlayerManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.11.2025.
//

import SpriteKit

protocol BattleEnemyManagerProtocol: AnyObject {
    var enemyNode: SKSpriteNode { get }
    func setupEnemy()
    func startIdleAnimation()
    func attack()
    func spawnNewEnemy()
    func killEnemy(completion: @escaping () -> Void)
    func enemyAtacks()
}

class BattleEnemyManager: BattleEnemyManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let enemyNode = SKSpriteNode()
    private var idleTextures: [SKTexture] = []
    private var attackTextures: [SKTexture] = []
    private var deathTextures: [SKTexture] = []
    private let enemyTypes = ["Vampire"]
    private var currentEnemyType: String = "Vampire"
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    // MARK: - LOGIC
    
    func spawnNewEnemy() {
        currentEnemyType = enemyTypes.randomElement() ?? "Vampire"
        loadTextures(for: currentEnemyType)
        enemyNode.removeFromParent()
        enemyNode.removeAllActions()
        setupEnemy()
        startIdleAnimation()
    }
    
    private func loadTextures(for type: String) {
        idleTextures = loadCircleAtlas(named: "\(type)Idle", prefix: "\(type.lowercased())_idle_")
        attackTextures = loadAtlas(named: "\(type)Attack", prefix: "\(type.lowercased())_attack_")
        deathTextures = loadAtlas(named: "\(type)Death", prefix: "\(type.lowercased())_death_")
    }
    
    private func loadCircleAtlas(named atlasName: String, prefix: String) -> [SKTexture] {
        let atlas = SKTextureAtlas(named: atlasName)
        var textures: [SKTexture] = []
        var index = 0
        while index < atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(prefix)\(index)"))
            index += 1
        }
        index -= 1
        while index >= 0 {
            textures.append(atlas.textureNamed("\(prefix)\(index)"))
            index -= 1
        }
        return textures
    }
    
    private func loadAtlas(named atlasName: String, prefix: String) -> [SKTexture] {
        let atlas = SKTextureAtlas(named: atlasName)
        var textures: [SKTexture] = []
        for i in 0..<atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(prefix)\(i)"))
        }
        return textures
    }
    
    func killEnemy(completion: @escaping () -> Void) {
        let animate = SKAction.animate(with: deathTextures, timePerFrame: 0.3)
        let notify = SKAction.run { completion() }
        let delete = SKAction.run {
            self.enemyNode.removeAllActions()
            self.enemyNode.removeFromParent()
        }
        let animationDuration = Double(deathTextures.count) * 0.1
        let targetWidth = BattleConstant.enemySize * 0.6
        let targetHeight = BattleConstant.enemySize * 0.6
        let shrink = SKAction.resize(toWidth: targetWidth, height: targetHeight, duration: animationDuration)
        let visualEffects = SKAction.group([animate, shrink])
        
        enemyNode.size = CGSize(width: BattleConstant.enemySize * 0.6, height: BattleConstant.enemySize * 0.6)
        enemyNode.run(
            SKAction.sequence([visualEffects, delete,notify]),
            withKey: GameConstant.deathCharacterAction
        )
    }
    
    func enemyAtacks() {
        
    }
    
    func setupEnemy() {
        guard let firstFrame = idleTextures.first, let scene = scene else { return }
        enemyNode.texture = firstFrame
        enemyNode.size = CGSize(width: BattleConstant.enemySize, height: BattleConstant.enemySize)
        enemyNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        enemyNode.position = CGPoint(
            x: scene.size.width * 0.7,
            y: BattleConstant.characterPosition
        )
        enemyNode.xScale = -1.0 
        enemyNode.zPosition = 3
        scene.addChild(enemyNode)
    }
    
    // MARK: - ANIMATIONS
    
    func startIdleAnimation() {
        let animate = SKAction.animate(with: idleTextures, timePerFrame: GameConstant.waitingTimePerFrame)
        enemyNode.run(SKAction.repeatForever(animate), withKey: GameConstant.waitingCharacterAnimation)
    }
    
    func attack() {
        let animate = SKAction.animate(with: attackTextures, timePerFrame: 0.1)
        let returnToIdle = SKAction.run { [weak self] in self?.startIdleAnimation() }
        enemyNode.run(SKAction.sequence([animate, returnToIdle]), withKey: "attack")
    }
}
