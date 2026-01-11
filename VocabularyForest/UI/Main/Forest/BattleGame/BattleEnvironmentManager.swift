//
//  BattleEnvironmentManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SpriteKit

protocol BattleEnvironmentManagerProtocol: AnyObject {
    var backgroundNode: SKSpriteNode { get }
    func moveBackground(direction: HorizontalDirection)
    func stopBackground()
    func nextBackground()
    func correctAnswer()
    func wrongAnswer()
    func userWon()
    func enemyWon()
    func showGate()
    func hideGate()
    func setupEnvironment(enemyModel: BattleEnemyModel)
    func update()
    func startMagic(magic: MagicType, startPoint: CGPoint, endPoint: CGPoint, hitted: @escaping () -> Void)
}

private extension BattleEnvironmentManager {
    enum Constant {
        static let celebrateTextureNames = ["Celebrate_0","Celebrate_1","Celebrate_2"]
        static let loseTextureNames = ["Lose_0"]
    }
}

class BattleEnvironmentManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var celebrateCount = 0
    private var currentGameIndex = 0
    private var backgroundTextures: [SKTexture] = []
    private var magicFlyTextures: [SKTexture] = []
    private var magicExplodeTextures: [SKTexture] = []
    private var explodeTextures: [SKTexture] = []
    private var blackHoleTextures: [SKTexture] = []
    var backgroundNode = SKSpriteNode()
    var magicNode = SKSpriteNode()
    var explodeNode = SKSpriteNode()
    var blackHoleNode = SKSpriteNode()

    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func setupEnvironment(enemyModel: BattleEnemyModel) {
        setupBackgroundTextures()
        setupBackground(model: enemyModel)
        setupUI()
    }
    
    private func setupBackgroundTextures() {
        let atlas = SKTextureAtlas(named: "Battle_backgrounds")
        for i in 0..<atlas.textureNames.count {
            backgroundTextures.append(atlas.textureNamed("battle_background_\(i)"))
        }
        let blackAtlas = SKTextureAtlas(named: "BlackHole")
        for i in 0..<blackAtlas.textureNames.count {
            blackHoleTextures.append(blackAtlas.textureNamed("black_hole_\(i)"))
        }
    }
    
    private func setupMagic(magic: MagicType) {
        var newFlyList: [SKTexture] = []
        var newExplodeList: [SKTexture] = []
        switch magic {
        case .fire:
            let flyAtlas = SKTextureAtlas(named: "FireMagicFly")
            for i in 1...flyAtlas.textureNames.count{
                newFlyList.append(flyAtlas.textureNamed("fire_fly_\(i)"))
            }
            let explodeAtlas = SKTextureAtlas(named: "FireMagicExplode")
            for i in 1...explodeAtlas.textureNames.count{
                newExplodeList.append(explodeAtlas.textureNamed("fire\(i)"))
            }
        case .darkMagic:
            let flyAtlas = SKTextureAtlas(named: "DarkMagicFly")
            for i in 1...flyAtlas.textureNames.count{
                newFlyList.append(flyAtlas.textureNamed("comet_fly_\(i)"))
            }
            let explodeAtlas = SKTextureAtlas(named: "DarkMagicExplode")
            for i in 1...explodeAtlas.textureNames.count{
                newExplodeList.append(explodeAtlas.textureNamed("comet\(i)"))
            }
        case .ice:
            let flyAtlas = SKTextureAtlas(named: "IceMagicFly")
            for i in 1...flyAtlas.textureNames.count{
                newFlyList.append(flyAtlas.textureNamed("ice_fly_\(i)"))
            }
            let explodeAtlas = SKTextureAtlas(named: "IceMagicExplode")
            for i in 1...explodeAtlas.textureNames.count{
                newExplodeList.append(explodeAtlas.textureNamed("ice\(i)"))
            }
        case .death:
            let flyAtlas = SKTextureAtlas(named: "DeathMagicFly")
            for i in 1...flyAtlas.textureNames.count{
                newFlyList.append(flyAtlas.textureNamed("scull_fly_\(i)"))
            }
            let explodeAtlas = SKTextureAtlas(named: "DeathMagicExplode")
            for i in 1...explodeAtlas.textureNames.count{
                newExplodeList.append(explodeAtlas.textureNamed("scull\(i)"))
            }
        case .psychic:
            let flyAtlas = SKTextureAtlas(named: "PsychicMagicFly")
            for i in 1...flyAtlas.textureNames.count{
                newFlyList.append(flyAtlas.textureNamed("spiral_fly_\(i)"))
            }
            let explodeAtlas = SKTextureAtlas(named: "PsychicMagicExplode")
            for i in 1...explodeAtlas.textureNames.count{
                newExplodeList.append(explodeAtlas.textureNamed("spiral\(i)"))
            }
        }
        magicFlyTextures = newFlyList
        magicExplodeTextures = newExplodeList
    }
}

// MARK: - BATTLE PROTOCOL

extension BattleEnvironmentManager: BattleEnvironmentManagerProtocol {
    
    func showGate() {
        blackHoleNode.isHidden = false
        let animationAction = SKAction.animate(with: blackHoleTextures, timePerFrame: BattleConstant.movingTimePerFrame)
        blackHoleNode.run(SKAction.repeatForever(animationAction))
    }
    
    func hideGate() {
        blackHoleNode.isHidden = true
        blackHoleNode.removeAllActions()
    }
    
    func correctAnswer() {
        if let textureName = Constant.celebrateTextureNames[safe: celebrateCount % Constant.celebrateTextureNames.count] {
            explodeTextures = []
            explodeNode.isHidden = false
            let atlas = SKTextureAtlas(named: textureName)
            for i in 0..<atlas.textureNames.count {
                explodeTextures.append(atlas.textureNamed("\(textureName.lowercased())_\(i)"))
            }
            let animationAction = SKAction.animate(with: explodeTextures, timePerFrame: 0.06)
            let hideAction = SKAction.run { [weak self] in
                guard let self else { return }
                self.explodeNode.isHidden = true
            }
            explodeNode.run(SKAction.sequence([animationAction,hideAction]))
            celebrateCount += 1
        }
    }
    
    func wrongAnswer() {
        if let textureName = Constant.loseTextureNames[safe: 0] {
            explodeTextures = []
            explodeNode.isHidden = false
            let atlas = SKTextureAtlas(named: textureName)
            for i in 0..<atlas.textureNames.count {
                explodeTextures.append(atlas.textureNamed("lose_\(i)"))
            }
            let animationAction = SKAction.animate(with: explodeTextures, timePerFrame: 0.06)
            let hideAction = SKAction.run { [weak self] in
                guard let self else { return }
                self.explodeNode.isHidden = true
            }
            explodeNode.run(SKAction.sequence([animationAction,hideAction]))
            celebrateCount += 1
        }
    }
    
    func userWon() {
        if let textureName = Constant.celebrateTextureNames[safe: celebrateCount % Constant.celebrateTextureNames.count] {
            explodeTextures = []
            explodeNode.isHidden = false
            let atlas = SKTextureAtlas(named: textureName)
            for i in 0..<atlas.textureNames.count {
                explodeTextures.append(atlas.textureNamed("\(textureName.lowercased())_\(i)"))            }
            let animationAction = SKAction.animate(with: explodeTextures, timePerFrame: 0.06)
            let hideAction = SKAction.run { [weak self] in
                guard let self else { return }
                self.explodeNode.isHidden = true
            }
            explodeNode.run(SKAction.sequence([animationAction,hideAction]))
            celebrateCount += 1
        }
    }
    
    func enemyWon() {
        if let textureName = Constant.loseTextureNames[safe: 0] {
            explodeTextures = []
            explodeNode.isHidden = false
            let atlas = SKTextureAtlas(named: textureName)
            for i in 0..<atlas.textureNames.count {
                explodeTextures.append(atlas.textureNamed("lose_\(i)"))
            }
            let animationAction = SKAction.animate(with: explodeTextures, timePerFrame: 0.06)
            let hideAction = SKAction.run { [weak self] in
                guard let self else { return }
                self.explodeNode.isHidden = true
            }
            explodeNode.run(SKAction.sequence([animationAction,hideAction]))
            celebrateCount += 1
        }
    }
    
    func startMagic(magic: MagicType, startPoint: CGPoint, endPoint: CGPoint, hitted: @escaping () -> Void) {
        setupMagic(magic: magic)
        magicNode.position = startPoint
        magicNode.zPosition = 10
        magicNode.size = GameConstant.magicSize
        scene?.addChild(magicNode)
        let flyTimePeriod = GameConstant.flyTime / Double(magicFlyTextures.count * 2)
        let flyAnimateAction = SKAction.animate(with: magicFlyTextures, timePerFrame: flyTimePeriod)
        let flyAnimation = SKAction.animate(with: magicFlyTextures.suffix(2), timePerFrame: flyTimePeriod)
        let flyAnimationForever = SKAction.repeatForever(flyAnimation)
        let flyMoveAction = SKAction.move(to: endPoint, duration: GameConstant.flyTime)
        let flyFunction = SKAction.run { [weak self] in
            guard let self else { return }
            let combinedFly = SKAction.sequence([flyAnimateAction, flyAnimationForever])
            self.magicNode.run(combinedFly, withKey: "flyAnimation")
        }
        let callHitted = SKAction.run { [weak self] in
            guard let self else { return }
            self.magicNode.removeAction(forKey: "flyAnimation")
            hitted()
        }
        let explodeTimePeriod = GameConstant.explodeTime / Double(magicExplodeTextures.count)
        let explodeAnimation = SKAction.animate(with: magicExplodeTextures, timePerFrame: explodeTimePeriod)
        let explodeFinished = SKAction.run { [ weak self ] in
            guard let self else { return }
            self.magicNode.removeFromParent()
            self.magicNode.removeAllActions()
        }
        magicNode.run(SKAction.sequence([flyFunction, flyMoveAction, callHitted, explodeAnimation, explodeFinished]))
    }
    
    // MARK: - SETUP FUNCTIONS

    func setupBackground(model: BattleEnemyModel) {
        let backTexture = SKTexture(imageNamed: model.background)
        guard let firstFrame = backgroundTextures.first, let scene = scene else { return }
        switch model {
        case .classic:
            backgroundNode.texture = firstFrame
        default:
            backgroundNode.texture = backTexture
        }
        backgroundNode.size = CGSize(width: scene.size.width * 2, height: scene.size.height)
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        backgroundNode.position = CGPoint(
            x: scene.size.width / 2,
            y: 0
        )
        backgroundNode.zPosition = 3
        scene.addChild(backgroundNode)
    }
    
    func nextBackground() {
        currentGameIndex += 1
        guard let newFrame = backgroundTextures[safe: currentGameIndex], let _ = scene else { return }
        backgroundNode.texture = newFrame
    }
    
    func setupUI() {
        guard let scene else { return }
        explodeNode.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.5)
        explodeNode.zPosition = 15
        explodeNode.size = CGSize(width: scene.size.width / 2, height: scene.size.width / 2)
        blackHoleNode.position = CGPoint(x: scene.size.width * 0.85, y: BattleConstant.characterPosition + 50)
        blackHoleNode.zPosition = 4
        blackHoleNode.size = CGSize(width: scene.size.width / 3, height: scene.size.width / 3)
        blackHoleNode.isHidden = true
        blackHoleNode.physicsBody = SKPhysicsBody(circleOfRadius: blackHoleNode.size.width / 2)
        blackHoleNode.physicsBody?.isDynamic = false        
        blackHoleNode.physicsBody?.categoryBitMask = PhysicsCategory.blackHole
        blackHoleNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        blackHoleNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        scene.addChild(blackHoleNode)
        scene.addChild(explodeNode)
        scene.addChild(scoreLabel)
    }
    
    func update() {
        //print("upd")
    }
    
    func moveBackground(direction: HorizontalDirection) {
        guard let scene = scene else { return }
        
        for node in scene.children {
            if node == backgroundNode {
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
}
