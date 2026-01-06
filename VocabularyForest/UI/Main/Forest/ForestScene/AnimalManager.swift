//
//  AnimalManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.12.2025.
//

import SpriteKit

protocol AnimalManagerProtocol: AnyObject {
    var animalNode: SKSpriteNode { get }
    var animalDirection: GameDirection { get }
    func startMoving()
    func stopMoving()
    func changeDirection()
    func setupAnimalManager(model: AnimalModel)
}

class AnimalManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let currentAnimalNode = SKSpriteNode()
    private var idleTextures: [SKTexture] = []
    private var walkingTextures: [SKTexture] = []
    private var jumpTextures: [SKTexture] = []
    private var animalModel: AnimalModel? = nil
    var direction: GameDirection = .right
    private var timer: Timer? = nil
    private var isJumping: Bool = false
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
    }
}

// MARK: - HELPERS

private extension AnimalManager {
    
    // MARK: - SETUP ASSETS
    
    func loadTextures(for type: String) {
        idleTextures = loadAtlas(named: "\(type)Idle", prefix: "\(type.lowercased())_idle_")
        jumpTextures = loadAtlas(named: "\(type)Jump", prefix: "\(type.lowercased())_jump_")
        walkingTextures = loadAtlas(named: "\(type)Walk", prefix: "\(type.lowercased())_walk_")
    }

    func loadCircleAtlas(named atlasName: String, prefix: String) -> [SKTexture] {
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

    func loadAtlas(named atlasName: String, prefix: String) -> [SKTexture] {
        let atlas = SKTextureAtlas(named: atlasName)
        var textures: [SKTexture] = []
        for i in 0..<atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(prefix)\(i)"))
        }
        return textures
    }
    
    // MARK: - ACTIONS
    
    func randomActions() {
        if (Bool.random()) {
            direction = .left
        } else {
            direction = .right
        }
        currentAnimalNode.xScale = direction == .left ? -1 : 1
        var runCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [ weak self ] timer in
            guard let self else { return }
            runCount += 1
            if runCount == 5 {
                moveAnimal()
                walkAnimation()
            }else if runCount == 10 {
                jumpAnimation { [weak self] in
                    guard let self else { return }
                    walkAnimation()
                }
            }
            else if runCount == 16 {
                stopMove()
                idleAnimation()
            }
            if runCount == 20 {
                runCount = 0
            }
        })
    }

    func stopMove() {
        currentAnimalNode.removeAction(forKey: GameConstant.movingCharacterAction)
        currentAnimalNode.removeAction(forKey: GameConstant.movingCharacterAnimation)
        currentAnimalNode.removeAllActions()
        timer?.invalidate()
    }

    func setupAnimal(animal: AnimalModel) {
        loadTextures(for: animal.assetName)
        setupAnimalFrames(model: animal)
        idleAnimation()
        randomActions()
        currentAnimalNode.name = "Animal"
    }
    
    func setupAnimalFrames(model: AnimalModel) {
        guard let firstFrame = idleTextures.first, let scene = scene else { return }
        currentAnimalNode.texture = firstFrame
        currentAnimalNode.size = CGSize(width: GameConstant.gameHeightSize * 0.1, height: GameConstant.gameHeightSize * 0.1)
        currentAnimalNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        currentAnimalNode.position = CGPoint(
            x: scene.size.width / 2,
            y: GameConstant.floorHeightSize * 0.65 + model.yPosition)
        currentAnimalNode.xScale = -1.0
        currentAnimalNode.zPosition = 3.0 - (model.yPosition / 50)
        scene.addChild(currentAnimalNode)
    }
    
    // MARK: - ANIMATIONS
    
    func idleAnimation() {
        let animate = SKAction.animate(with: idleTextures, timePerFrame: GameConstant.waitingTimePerFrame * 2)
        currentAnimalNode.run(SKAction.repeatForever(animate), withKey: GameConstant.waitingCharacterAnimation )
    }
    
    func moveAnimal() {
        currentAnimalNode.removeAction(forKey: GameConstant.movingCharacterAction)
        let moveAmount: CGFloat = (direction == .right) ? (50 + CGFloat.random(in: -15...15)) : (
            -50 + CGFloat.random(in: -15...15)
        )
        let move = SKAction.moveBy(x: moveAmount, y: 0, duration: 1.0)
        let repeatAction = SKAction.repeatForever(move)
        currentAnimalNode.run(repeatAction, withKey: GameConstant.movingCharacterAction)
    }
    
    func walkAnimation() {
        let animate = SKAction.animate(with: walkingTextures, timePerFrame: GameConstant.waitingTimePerFrame)
        let animateAction = SKAction.repeatForever(animate)
        currentAnimalNode.run(
            animateAction,
            withKey: GameConstant.movingCharacterAnimation
        )
    }
    
    func jumpAnimation(completion: @escaping () -> Void) {
        currentAnimalNode.removeAction(forKey: GameConstant.movingCharacterAnimation)
        let animate = SKAction.animate(with: jumpTextures, timePerFrame: GameConstant.jumpTimePerFrame)
        let jumpFinish = SKAction.run {
            completion()
        }
        currentAnimalNode.run(
            SKAction.sequence(
                [animate, jumpFinish]
            ),
            withKey: GameConstant.jumpAnimation
        )
    }
}

extension AnimalManager: AnimalManagerProtocol {
    
    func startMoving() {
        moveAnimal()
        walkAnimation()
    }

    func stopMoving() {
        stopMove()
        idleAnimation()
    }
    
    func changeDirection() {
        direction = direction == .left ? .right : .left
        currentAnimalNode.xScale = direction == .left ? -1 : 1
        moveAnimal()
    }
    
    func setupAnimalManager(model: AnimalModel) {
        setupAnimal(animal: model)
    }
    
    var animalNode: SKSpriteNode {
        currentAnimalNode
    }
    
    var animalDirection: GameDirection {
        direction
    }
}
