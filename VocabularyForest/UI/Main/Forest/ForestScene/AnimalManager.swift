// MARK: - AnimalManager.swift

//
//  AnimalManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.12.2025.
//

import SpriteKit

// MARK: - ANIMAL MANAGER PROTOCOL

protocol AnimalManagerProtocol: AnyObject, TapComponentProtocol, TalkProtocol {
    var animalDirection: HorizontalDirection { get }
    var node: SKSpriteNode { get }
    var model: AnimalModel? { get }
    func startMoving()
    func stopMoving()
    func changeDirection()
    func setupAnimalManager(model: AnimalModel)
}

// MARK: - CONSTANTS

extension AnimalManager {
    enum Constants {
        static let zero: CGFloat = 0.0
        
        // Bubble Animations
        static let bubbleInitialScale: CGFloat = 0.0
        static let bubbleScaleDuration: TimeInterval = 0.2
        static let removeBubbleScaleTarget: CGFloat = 0.0
        static let removeBubbleDuration: TimeInterval = 0.1
        
        // Animal Frame Setup
        static let frameSizeMultiplier: CGFloat = 0.1
        static let anchorPointX: CGFloat = 0.5
        static let anchorPointY: CGFloat = 0.0
        static let screenWidthDivider: CGFloat = 2.0
        static let floorHeightMultiplier: CGFloat = 0.65
        static let baseZPosition: CGFloat = 3.0
        static let zPositionDivider: CGFloat = 50.0
        
        // Movement & Animations
        static let idleTimeMultiplier: Double = 2.0
        static let moveBaseAmount: CGFloat = 50.0
        static let moveRandomLowerBound: CGFloat = -15.0
        static let moveRandomUpperBound: CGFloat = 15.0
        static let moveDuration: TimeInterval = 1.0
        
        // Timers & Action Limits
        static let randomActionTimerInterval: TimeInterval = 1.0
        static let walkRunCount: Int = 5
        static let jumpRunCount: Int = 10
        static let idleRunCount: Int = 16
        static let resetRunCount: Int = 20
        
        // Scale Values
        static let scaleLeft: CGFloat = -1.0
        static let scaleRight: CGFloat = 1.0
    }
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
    
    func loadTextures(for model: AnimalModel) {
        idleTextures.removeAll()
        jumpTextures.removeAll()
        walkingTextures.removeAll()

        let resolvedPath = model.mediaLocalPath ?? ForestLocalMediaPathResolver.resolvePath(for: model.assetName)
        idleTextures = LocalMediaBundleLoader.textures(rootPath: resolvedPath, animationKey: .idle)
        jumpTextures = LocalMediaBundleLoader.textures(rootPath: resolvedPath, animationKey: .jump)
        walkingTextures = LocalMediaBundleLoader.textures(rootPath: resolvedPath, animationKey: .walk)

        guard !idleTextures.isEmpty, !jumpTextures.isEmpty, !walkingTextures.isEmpty else {
            let type = model.assetName
            idleTextures = loadAtlas(named: "\(type)Idle", prefix: "\(type.lowercased())_idle_")
            jumpTextures = loadAtlas(named: "\(type)Jump", prefix: "\(type.lowercased())_jump_")
            walkingTextures = loadAtlas(named: "\(type)Walk", prefix: "\(type.lowercased())_walk_")
            return
        }
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
        currentAnimalNode.xScale = direction == .left ? Constants.scaleLeft : Constants.scaleRight
        var runCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: Constants.randomActionTimerInterval, repeats: true, block: { [ weak self ] timer in
            guard let self else { return }
            runCount += 1
            if runCount == Constants.walkRunCount {
                moveAnimal()
                walkAnimation()
            }else if runCount == Constants.jumpRunCount {
                jumpAnimation { [weak self] in
                    guard let self else { return }
                    walkAnimation()
                }
            }
            else if runCount == Constants.idleRunCount {
                stopMove()
                idleAnimation()
            }
            if runCount == Constants.resetRunCount {
                runCount = 0
            }
        })
    }

    func stopMove() {
        currentAnimalNode.removeAction(forKey: GameConstant.movingCharacterAction)
        currentAnimalNode.removeAction(forKey: GameConstant.movingCharacterAnimation)
    }

    func setupAnimal(animal: AnimalModel) {
        loadTextures(for: animal)
        setupAnimalFrames(model: animal)
        idleAnimation()
        randomActions()
        currentAnimalNode.name = "Animal"
        animalModel = animal
    }
    
    func setupAnimalFrames(model: AnimalModel) {
        guard let firstFrame = idleTextures.first, let scene = scene else { return }
        currentAnimalNode.texture = firstFrame
        currentAnimalNode.size = CGSize(width: GameConstant.gameHeightSize * Constants.frameSizeMultiplier, height: GameConstant.gameHeightSize * Constants.frameSizeMultiplier)
        currentAnimalNode.anchorPoint = CGPoint(x: Constants.anchorPointX, y: Constants.anchorPointY)
        currentAnimalNode.position = CGPoint(
            x: scene.size.width / Constants.screenWidthDivider,
            y: GameConstant.floorHeightSize * Constants.floorHeightMultiplier + model.yPosition)
        currentAnimalNode.xScale = Constants.scaleLeft
        currentAnimalNode.zPosition = Constants.baseZPosition - (model.yPosition / Constants.zPositionDivider)
        let originalSize = firstFrame.size()
        if originalSize.height > Constants.zero {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = ComponentSizeConstant.animalHeight * aspectRatio
            currentAnimalNode.size = CGSize(width: targetWidth, height: ComponentSizeConstant.animalHeight)
        }
        scene.addChild(currentAnimalNode)
    }
    
    // MARK: - ANIMATIONS
    
    func idleAnimation() {
        let animate = SKAction.animate(with: idleTextures, timePerFrame: GameConstant.waitingTimePerFrame * Constants.idleTimeMultiplier)
        currentAnimalNode.run(SKAction.repeatForever(animate), withKey: GameConstant.waitingCharacterAnimation )
    }
    
    func moveAnimal() {
        currentAnimalNode.removeAction(forKey: GameConstant.movingCharacterAction)
        let moveAmount: CGFloat = (direction == .right) ? (Constants.moveBaseAmount + CGFloat.random(in: Constants.moveRandomLowerBound...Constants.moveRandomUpperBound)) : (
            -Constants.moveBaseAmount + CGFloat.random(in: Constants.moveRandomLowerBound...Constants.moveRandomUpperBound)
        )
        let move = SKAction.moveBy(x: moveAmount, y: Constants.zero, duration: Constants.moveDuration)
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
        if let existingBubble = currentAnimalNode.childNode(withName: "menu_bubble") {
            existingBubble.removeFromParent()
            isMenuOpen = false
            return
        }
        
        isMenuOpen = true
        let displayName = animalModel?.characterName.isEmpty == false ? animalModel?.characterName : animalModel?.assetName
        
        let bubble = ComponentBubble.createAnimalMenuBubble(parentSize: currentAnimalNode.size, displayName: displayName)
        
        bubble.setScale(Constants.bubbleInitialScale)
        currentAnimalNode.addChild(bubble)
        
        let targetXScale: CGFloat = currentAnimalNode.xScale < Constants.zero ? Constants.scaleLeft : Constants.scaleRight
        let scaleAction = SKAction.scaleX(to: targetXScale, y: Constants.scaleRight, duration: Constants.bubbleScaleDuration)
        bubble.run(scaleAction)
        
        ComponentBubble.applyAutoCloseAnimation(to: bubble) { [weak self] in
            self?.isMenuOpen = false
        }
    }
}

// MARK: - ANIMAL MANAGER PROTOCOL

extension AnimalManager: AnimalManagerProtocol {
    
    var model: AnimalModel? {
        animalModel
    }
    
    func updateName(name: String) {
        animalModel?.characterName = name
    }
    
    func tapComponent() {
        createInteractionBubble()
    }
    
    func startMoving() {
        randomActions()
    }

    func stopMoving() {
        stopMove()
        idleAnimation()
        timer?.invalidate()
    }
    
    func changeDirection() {
        direction = direction == .left ? .right : .left
        let newScale: CGFloat = direction == .left ? Constants.scaleLeft : Constants.scaleRight
        currentAnimalNode.xScale = newScale
        if let bubble = currentAnimalNode.childNode(withName: "menu_bubble") {
            bubble.xScale = newScale
        }
        moveAnimal()
    }
    
    func setupAnimalManager(model: AnimalModel) {
        setupAnimal(animal: model)
    }
    
    var node: SKSpriteNode {
        currentAnimalNode
    }
    
    var animalDirection: HorizontalDirection {
        direction
    }
}

// MARK: - TALK PROTOCOL

extension AnimalManager: TalkProtocol {
    
    func talk(text: String) {
        if let existingBubble = currentAnimalNode.childNode(withName: "talk_bubble") {
            existingBubble.removeFromParent()
        }
        
        let bubble = ComponentBubble.createTalkBubble(parentSize: currentAnimalNode.size, parentXScale: currentAnimalNode.xScale, text: text)
        currentAnimalNode.addChild(bubble)
    }
    
    func removeBubble() {
        if let menuBubble = currentAnimalNode.childNode(withName: "menu_bubble") {
            menuBubble.run(.sequence([
                .scale(to: Constants.removeBubbleScaleTarget, duration: Constants.removeBubbleDuration),
                .removeFromParent()
            ]))
            isMenuOpen = false
        }
        
        if let talkBubble = currentAnimalNode.childNode(withName: "talk_bubble") {
            talkBubble.run(.sequence([
                .scale(to: Constants.removeBubbleScaleTarget, duration: Constants.removeBubbleDuration),
                .removeFromParent()
            ]))
        }
    }
}
