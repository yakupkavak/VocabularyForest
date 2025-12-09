//
//  EnemyPlayerManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.11.2025.
//

import SpriteKit

protocol BattleEnemyManagerProtocol: AnyObject {
    var enemyNode: SKSpriteNode { get }
    func startIdleAnimation()
    func enemyAtacks(endPointX: CGFloat, hitted: @escaping () -> Void)
    func spawnNextEnemy()
    func killEnemy(completion: @escaping (Bool) -> Void)
    func setupEnemyManager(models: [EnemyCharacterModel])
}

class BattleEnemyManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let enemyNode = SKSpriteNode()
    private var idleTextures: [SKTexture] = []
    private var walkingTextures: [SKTexture] = []
    private var attackTextures: [SKTexture] = []
    private var deathTextures: [SKTexture] = []
    private var enemyTypes: [EnemyCharacterModel]? = nil
    private var currentEnemyType: EnemyCharacterModel? = nil
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    // MARK: - LOGIC
    
    private func loadTextures(for type: String) {
        idleTextures = loadCircleAtlas(named: "\(type)Idle", prefix: "\(type.lowercased())_idle_")
        attackTextures = loadAtlas(named: "\(type)Attack", prefix: "\(type.lowercased())_attack_")
        deathTextures = loadAtlas(named: "\(type)Death", prefix: "\(type.lowercased())_death_")
        walkingTextures = loadAtlas(named: "\(type)Walk", prefix: "\(type.lowercased())_walk_")
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
    
    // MARK: - ANIMATIONS
    
    func attack() {
        let animate = SKAction.animate(with: attackTextures, timePerFrame: 0.1)
        let returnToIdle = SKAction.run { [weak self] in self?.startIdleAnimation() }
        enemyNode.run(SKAction.sequence([animate, returnToIdle]), withKey: "attack")
    }
}

// MARK: - HELPERS

private extension BattleEnemyManager {
    func spawnNewEnemy(enemyName: String) {
        loadTextures(for: enemyName)
        enemyNode.removeFromParent()
        enemyNode.removeAllActions()
        setupEnemy()
        startIdleAnimation()
    }
    
    func setupEnemy() {
        guard let firstFrame = idleTextures.first, let scene = scene else { return }
        enemyNode.texture = firstFrame
        let originalSize = firstFrame.size()
        let targetHeight = GameConstant.gameHeightSize * 0.2
        if originalSize.height > 0 {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = targetHeight * aspectRatio
            enemyNode.size = CGSize(width: targetWidth, height: targetHeight)
        }
        /*
        enemyNode.size = CGSize(width: BattleConstant.enemySize, height: BattleConstant.enemySize)*/
        enemyNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        enemyNode.position = CGPoint(
            x: ["SandDragon","FireDragon"]
                .contains(currentEnemyType?.assetName) ? scene.size.width * 0.65 : scene.size.width * 0.7,
            y:["Vampire","SandDragon","FireDragon","IceElemental","NatureElemental","FireElemental"]
                .contains(currentEnemyType?.assetName) ? BattleConstant.characterPosition : BattleConstant.characterPosition * 0.85
        )
        enemyNode.xScale = -1.0
        enemyNode.zPosition = 3
        scene.addChild(enemyNode)
    }
}

extension BattleEnemyManager: BattleEnemyManagerProtocol {
    
    func setupEnemyManager(models: [EnemyCharacterModel]) {
        enemyTypes = models
        currentEnemyType = enemyTypes?.first
        if let currentEnemyType {
            spawnNewEnemy(enemyName: currentEnemyType.assetName)
        }
    }
    
    func spawnNextEnemy() {
        if let enemyTypes = enemyTypes, let currentEnemyType = currentEnemyType {
            if let currentIndex = enemyTypes.firstIndex(of: currentEnemyType) {
                let nextIndex = currentIndex + 1
                let nextEnemy = enemyTypes[safe: nextIndex]
                if let nextEnemy {
                    self.currentEnemyType = nextEnemy
                    spawnNewEnemy(enemyName: nextEnemy.assetName)
                }
            }
        }
    }
    
    func startIdleAnimation() {
        let animate = SKAction.animate(with: idleTextures, timePerFrame: GameConstant.waitingTimePerFrame)
        enemyNode.run(SKAction.repeatForever(animate), withKey: GameConstant.waitingCharacterAnimation)
    }
    
    func killEnemy(completion: @escaping (Bool) -> Void) {
        let animate = SKAction.animate(with: deathTextures, timePerFrame: 0.3)
        let notify = SKAction.run {
            completion(
                ["Vampire","SandDragon","FireDragon","IceElemental","NatureElemental","FireElemental"].contains(self.currentEnemyType?.assetName))
        }
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
    
    func enemyAtacks(endPointX: CGFloat, hitted: @escaping () -> Void) {
        let moveAnimate = SKAction.animate(with: walkingTextures, timePerFrame: GameConstant.movingTimePerFrame)
        let moveAnimation = SKAction.repeatForever(moveAnimate)
        let moveAction = SKAction.move(
            to: CGPoint(
                x: endPointX + CGFloat(["Vampire","SandDragon","FireDragon","IceElemental","NatureElemental","FireElemental"]
                    .contains(currentEnemyType?.assetName) ? 100 : 30),
                y:[
                    "Vampire",
                    "SandDragon",
                    "FireDragon",
                    "IceElemental",
                    "NatureElemental",
                    "FireElemental"
                ]
                    .contains(currentEnemyType?.assetName) ? BattleConstant.characterPosition : BattleConstant.characterPosition * 0.85
            ),
            duration: GameConstant.walkingTime
        )
        let arriveFunction = SKAction.run { [weak self] in
            guard let self else { return }
            self.enemyNode.removeAction(forKey: "walking")
        }
        let killEnemyFunction = SKAction.run { [weak self] in
            guard let self else { return }
            guard self.attackTextures.count > 1 else {
                let simpleAnimate = SKAction.animate(with: self.attackTextures, timePerFrame: GameConstant.attackTimePerFrame)
                self.enemyNode.run(simpleAnimate)
                return
            }
            let firstPartTextures = Array(self.attackTextures.dropLast())
            let animatePart1 = SKAction.animate(with: firstPartTextures, timePerFrame: GameConstant.attackTimePerFrame, resize: false, restore: false)
            let lastPartTextures = Array(self.attackTextures.suffix(1))
            let animatePart2 = SKAction.animate(with: lastPartTextures, timePerFrame: GameConstant.attackTimePerFrame, resize: false, restore: false)
            let triggerAction = SKAction.run {
                hitted()
            }
            let stopAction = SKAction.run {
                self.enemyNode.removeAllActions()
                self.enemyNode.removeAction(forKey: "walking")
            }
            let fullSequence = SKAction.sequence([animatePart1, triggerAction, animatePart2, stopAction])
            self.enemyNode.run(fullSequence)
        }
        
        enemyNode.run(moveAnimation, withKey: "walking")
        enemyNode.run(SKAction.sequence([moveAction,arriveFunction,killEnemyFunction]))
    }
    
}
