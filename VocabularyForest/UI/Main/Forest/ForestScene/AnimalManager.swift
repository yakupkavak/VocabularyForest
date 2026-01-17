//
//  AnimalManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.12.2025.
//

import SpriteKit

protocol AnimalManagerProtocol: AnyObject {
    var animalNode: SKSpriteNode { get }
    var animalDirection: HorizontalDirection { get }
    var model: AnimalModel? { get }
    func startMoving()
    func stopMoving()
    func changeDirection()
    func setupAnimalManager(model: AnimalModel)
    func tapAnimal()
}

class AnimalManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    private var idleTextures: [SKTexture] = []
    private var walkingTextures: [SKTexture] = []
    private var jumpTextures: [SKTexture] = []
    private var animalModel: AnimalModel? = nil
    private var timer: Timer? = nil
    private var isJumping: Bool = false
    private var isMenuOpen = false
    let currentAnimalNode = SKSpriteNode()
    var direction: HorizontalDirection = .right

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
        let originalSize = firstFrame.size()
        if originalSize.height > 0 {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = ComponentSizeConstant.animalHeight * aspectRatio
            currentAnimalNode.size = CGSize(width: targetWidth, height: ComponentSizeConstant.animalHeight)
        }
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
    
    //MARK: - TAP GESTURE
    
    func createInteractionBubble() {
        if let existingBubble = animalNode.childNode(withName: "menu_bubble") {
            existingBubble.removeFromParent()
            isMenuOpen = false
            return
        }
        
        isMenuOpen = true
        let bubbleWidth: CGFloat = 120
        let bubbleHeight: CGFloat = 60
        let bubble = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 10)
        bubble.name = "menu_bubble"
        bubble.fillColor = .white
        bubble.strokeColor = .black
        bubble.lineWidth = 2
        bubble.zPosition = 100
        bubble.position = CGPoint(x: 0, y: animalNode.size.height + 40)
        
        let nameBtn = createButtonLabel(text: "İsim", name: "btn_update_name")
        nameBtn.position = CGPoint(x: -30, y: -5)
        bubble.addChild(nameBtn)
        
        let separator = SKShapeNode(rectOf: CGSize(width: 1, height: 30))
        separator.fillColor = .gray
        separator.strokeColor = .gray
        separator.position = CGPoint(x: 0, y: 0)
        bubble.addChild(separator)
        
        let posBtn = createButtonLabel(text: "Taşı", name: "btn_update_pos")
        posBtn.position = CGPoint(x: 30, y: -5)
        bubble.addChild(posBtn)
        
        bubble.setScale(0)
        animalNode.addChild(bubble)
        bubble.run(.scale(to: 1.0, duration: 0.2))
        
        let waitAction = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let updateState = SKAction.run { [weak self] in
            self?.isMenuOpen = false
        }
        let autoCloseSequence = SKAction.sequence([waitAction, fadeOut, remove, updateState])
        bubble.run(autoCloseSequence, withKey: "autoCloseTimer")
    }
    
    func createButtonLabel(text: String, name: String) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = text
        label.fontSize = 14
        label.fontColor = .black
        label.name = name
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }
}

// MARK: - ANIMAL MANAGER PROTOCOL

extension AnimalManager: AnimalManagerProtocol {
    
    var model: AnimalModel? {
        animalModel
    }
    
    func tapAnimal() {
        createInteractionBubble()
    }
    
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
    
    var animalDirection: HorizontalDirection {
        direction
    }
}

extension AnimalManager: TalkProtocol {
    var node: SKSpriteNode {
        animalNode
    }
    
    func talk(text: String) {
        print("")
    }
    
    func removeBubble() {
        if let bubble = animalNode.childNode(withName: "menu_bubble") {
            bubble.run(.sequence([
                .scale(to: 0, duration: 0.1),
                .removeFromParent()
            ]))
            isMenuOpen = false
        }
    }
}
