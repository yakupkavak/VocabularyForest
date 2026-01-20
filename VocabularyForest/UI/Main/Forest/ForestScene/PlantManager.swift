//
//  PlantManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.12.2025.
//

import SpriteKit

protocol PlantManagerProtocol: UpdatePositionProtocol, TapComponentProtocol {
    var model: TreeModel? { get }
    func setupPlant(model: TreeModel)
    func growPlant()
    func decreasePlant()
    func fadePlant()
    func perishPlant()
    func recoverPlant()
}

class PlantManager {
    
    // MARK: - PROPERTIES
    
    var plant = SKSpriteNode()
    private var treeModel: TreeModel? = nil
    private var isMenuOpen = false
    private weak var scene: SKScene?
    private var textures: [SKTexture] = []
    private var isPerished = false
    // MARK: - INIT
    
    init(scene: SKScene? = nil) {
        self.scene = scene
    }
}

// MARK: - HELPERS

private extension PlantManager {
    
    func loadTextures(for model: TreeModel) {
        let atlas = SKTextureAtlas(named: model.assetName)
        for i in 0..<atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(model.assetName.lowercased())_\(i)"))
        }
        setPlant(model: model)
        plant.zPosition = getZIndex(yPosition: model.yPosition)
    }
    
    func setPlant(model: TreeModel) {
        // FUTURE: - GROW PLANT
        plant.removeFromParent()
        guard let firstFrame = textures[safe: 1], let scene else {
            return
        }
        plant.texture = firstFrame
        // TODO: - SIZE
        let originalSize = firstFrame.size()
        if originalSize.height > 0 {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = ComponentSizeConstant.plantHeight * aspectRatio
            plant.size = CGSize(width: targetWidth, height: ComponentSizeConstant.plantHeight)
        }
        plant.anchorPoint = CGPoint(x: 0.5, y: 0)
        plant.position = CGPoint(
            x: GameConstant.gameWidthSize * model.xPosition,
            y: GameConstant.materialHeightSize * model.yPosition
        )
        plant.name = "plant"
        plant.zPosition = 10 - model.yPosition * 20.0
        treeModel = model
        scene.addChild(plant)
    }
    
    func createInteractionBubble() {
        if let existingBubble = plant.childNode(withName: "menu_bubble") {
            existingBubble.removeFromParent()
            isMenuOpen = false
            return
        }
        
        isMenuOpen = true
        let displayName = treeModel?.characterName.isEmpty == false ? treeModel?.characterName : treeModel?.assetName
        
        let bubbleWidth: CGFloat = 140
        let bubbleHeight: CGFloat = 90
        
        let bubble = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 10)
        bubble.name = "menu_bubble"
        bubble.fillColor = .brown500.withAlphaComponent(0.95)
        bubble.strokeColor = .black
        bubble.lineWidth = 2
        bubble.zPosition = 100
        bubble.position = CGPoint(x: 0, y: plant.size.height + 40)
        
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = displayName ?? String(localized: "Bitki")
        titleLabel.fontSize = 16
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 15)
        bubble.addChild(titleLabel)

        let headerSeparator = SKShapeNode(rectOf: CGSize(width: bubbleWidth - 20, height: 1))
        headerSeparator.fillColor = .black.withAlphaComponent(0.3)
        headerSeparator.strokeColor = .clear
        headerSeparator.position = CGPoint(x: 0, y: 5)
        bubble.addChild(headerSeparator)

        let nameBtn = createButtonLabel(text: String(localized: "İsim Değiştir"), name: "btn_update_name", maxWidth: 60)
        nameBtn.position = CGPoint(x: -32, y: -15)
        nameBtn.fontColor = .black
        bubble.addChild(nameBtn)
        
        let separator = SKShapeNode(rectOf: CGSize(width: 1, height: 25))
        separator.fillColor = .logoGreen
        separator.strokeColor = .logoGreen
        separator.position = CGPoint(x: 0, y: -15)
        bubble.addChild(separator)
        
        let posBtn = createButtonLabel(text: String(localized: "Taşı"), name: "btn_update_pos", maxWidth: 60)
        posBtn.position = CGPoint(x: 32, y: -15)
        posBtn.fontColor = .black
        bubble.addChild(posBtn)
        
        bubble.setScale(0)
        plant.addChild(bubble)
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
    
    func createButtonLabel(text: String, name: String, maxWidth: CGFloat? = nil) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = text
        label.fontSize = 14
        label.fontColor = .black
        label.name = name
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        if let width = maxWidth {
            label.numberOfLines = 0
            label.preferredMaxLayoutWidth = width
            label.lineBreakMode = .byWordWrapping
        }
        return label
    }

    func getScrollOffset() -> CGFloat {
        guard let scene = scene,
              let floor = scene.childNode(withName: ForestConstant.floorName) else { return 0 }
        let initialX = scene.size.width / 2
        return floor.position.x - initialX
    }
}

// MARK: - UPDATE PlantManager PROTOCOL

extension PlantManager: UpdatePositionProtocol {
    
    func confirmeChange() {
        if isPerished {
            perishPlant()
        }else {
            plant.color = .white
            plant.colorBlendFactor = 0.0
        }
    }
    
    func positionChange(direction: Directions) {
        switch direction {
        case .up:
            self.treeModel?.yPosition += ForestConstant.perVerticalMove
        case .down:
            self.treeModel?.yPosition -= ForestConstant.perVerticalMove
        case .right:
            self.treeModel?.xPosition += ForestConstant.perHorizontalMove
        case .left:
            self.treeModel?.xPosition -= ForestConstant.perHorizontalMove
        }
        let scrollOffset = getScrollOffset()
        if let yPosition = self.treeModel?.yPosition {
             plant.zPosition = getZIndex(yPosition: yPosition)
        }
        plant.position = CGPoint(
            x: (GameConstant.gameWidthSize * (self.treeModel?.xPosition ?? 0)) + scrollOffset,
            y: GameConstant.sculptureHeightSize * (self.treeModel?.yPosition ?? 0)
        )
    }
    
    func startPositionChange() {
        plant.color = .clickableText
        plant.colorBlendFactor = 0.9
    }

    func removeChange(x: CGFloat, y: CGFloat) {
        let scrollOffset = getScrollOffset()
        plant.position = CGPoint(
            x: (GameConstant.gameWidthSize * x) + scrollOffset,
            y: GameConstant.sculptureHeightSize * y
        )
        self.treeModel?.xPosition = x
        self.treeModel?.yPosition = y
        plant.zPosition = getZIndex(yPosition: y)
        plant.color = .white
        plant.colorBlendFactor = 0.0
    }
}

// MARK: - PLANT MANAGER PROTOCOL

extension PlantManager: PlantManagerProtocol {
    
    var model: TreeModel? {
        treeModel
    }
    
    var node: SKSpriteNode {
        plant
    }
    
    func updateName(name: String) {
        treeModel?.characterName = name
    }
    
    func tapComponent() {
        createInteractionBubble()
    }
    
    func setupPlant(model: TreeModel) {
        loadTextures(for: model)
    }
    
    func growPlant() {
        guard let secondFrame = textures[safe: 1] else {
            return
        }
        plant.texture = secondFrame
    }
    
    func decreasePlant() {
        guard let firstFrame = textures.first else {
            return
        }
        plant.texture = firstFrame
    }
    
    func fadePlant() {
        plant.color = .brown
        plant.colorBlendFactor = 0.4
    }
    
    func perishPlant() {
        plant.color = .brown
        plant.colorBlendFactor = 0.8
        isPerished = true
    }
    
    func recoverPlant() {
        isPerished = false
        plant.color = .white
        plant.colorBlendFactor = 0.0
    }
}

extension PlantManager: TalkProtocol {
    
    func talk(text: String) {
        print("")
    }
    
    func removeBubble() {
        if let bubble = plant.childNode(withName: "menu_bubble") {
            bubble.run(.sequence([
                .scale(to: 0, duration: 0.1),
                .removeFromParent()
            ]))
            isMenuOpen = false
        }
    }
}
