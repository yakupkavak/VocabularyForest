//
//  SculptureManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.12.2025.
//

import SpriteKit

protocol TapComponentProtocol {
    func tapComponent()
}

protocol SculptureManagerProtocol: AnyObject, UpdatePositionProtocol, TapComponentProtocol {
    var sculptureNode: SKSpriteNode { get }
    var model: SculptureModel? { get }
    func setupSculpture(model: SculptureModel)
    func setZIndex(index: Double)
}

class SculptureManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    private var sculptureModel: SculptureModel? = nil
    private var isMenuOpen = false
    var currentSculptureNode = SKSpriteNode()
    
    // MARK: - INIT
    init(scene: SKScene? = nil) {
        self.scene = scene
    }
}

// MARK: - HELPERS

private extension SculptureManager {
    
    func setModel(model: SculptureModel) {
        currentSculptureNode = SKSpriteNode(imageNamed: model.assetName)
        currentSculptureNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * model.xPosition,
            y: GameConstant.sculptureHeightSize * model.yPosition
        )
        let originalSize = currentSculptureNode.size
        if originalSize.height > 0 {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = ComponentSizeConstant.plantHeight * aspectRatio
            currentSculptureNode.size = CGSize(width: targetWidth, height: ComponentSizeConstant.sculptureHeight)
        }
        currentSculptureNode.name = "sculpture"
        currentSculptureNode.zPosition = 10.0 - model.yPosition * 20.0
        sculptureModel = model
        scene?.addChild(currentSculptureNode)
    }
     
    func createInteractionBubble() {
        if let existingBubble = currentSculptureNode.childNode(withName: "menu_bubble") {
            existingBubble.removeFromParent()
            isMenuOpen = false
            return
        }
        
        isMenuOpen = true
        let displayName = sculptureModel?.characterName.isEmpty == false ? sculptureModel?.characterName : sculptureModel?.assetName
        
        let bubbleWidth: CGFloat = 140
        let bubbleHeight: CGFloat = 90
        
        let bubble = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 10)
        bubble.name = "menu_bubble"
        bubble.fillColor = .brown500.withAlphaComponent(0.95)
        bubble.strokeColor = .black
        bubble.lineWidth = 2
        bubble.zPosition = 100
        bubble.position = CGPoint(x: 0, y: currentSculptureNode.size.height + 40)
        
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = displayName ?? String(localized: "Heykel")
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
        currentSculptureNode.addChild(bubble)
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
}

// MARK: - SCULPTURE MANAGER PROTOCOL

extension SculptureManager: SculptureManagerProtocol {
    
    var model: SculptureModel? {
        sculptureModel
    }
    
    func tapComponent() {
        createInteractionBubble()
    }
    
    func setupSculpture(model: SculptureModel) {
        setModel(model: model)
    }
    
    var sculptureNode: SKSpriteNode {
        currentSculptureNode
    }
    func setZIndex(index: Double) {
        currentSculptureNode.zPosition = index
    }
}

// MARK: - UPDATE POSITION PROTOCOL

extension SculptureManager: UpdatePositionProtocol {
    
    func confirmeChange() {
        currentSculptureNode.color = .white
        currentSculptureNode.colorBlendFactor = 0.0
    }
    
    func positionChange(direction: Directions) {
        switch direction {
        case .up:
            self.sculptureModel?.yPosition += ForestConstant.perVerticalMove
        case .down:
            self.sculptureModel?.yPosition -= ForestConstant.perVerticalMove
        case .right:
            self.sculptureModel?.xPosition += ForestConstant.perHorizontalMove
        case .left:
            self.sculptureModel?.xPosition -= ForestConstant.perHorizontalMove
        }
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * (self.sculptureModel?.xPosition ?? 0),
            y: GameConstant.sculptureHeightSize * (self.sculptureModel?.yPosition ?? 0)
        )
    }
    
    var node: SKSpriteNode {
        currentSculptureNode
    }
    
    func startPositionChange() {
        currentSculptureNode.color = .clickableText
        currentSculptureNode.colorBlendFactor = 0.9
    }

    func removeChange(x: CGFloat, y: CGFloat) {
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * x,
            y: GameConstant.sculptureHeightSize * y
        )
        self.sculptureModel?.xPosition = x
        self.sculptureModel?.yPosition = y
    }
}

// MARK: - TALK PROTOCOL

extension SculptureManager: TalkProtocol {
    
    func talk(text: String) {
        print("text")
    }
    
    func removeBubble() {
        if let bubble = currentSculptureNode.childNode(withName: "menu_bubble") {
            bubble.run(.sequence([
                .scale(to: 0, duration: 0.1),
                .removeFromParent()
            ]))
            isMenuOpen = false
        }
    }
}
