//
//  SculptureManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.12.2025.
//

import SpriteKit

protocol SculptureManagerProtocol: AnyObject {
    var sculptureNode: SKSpriteNode { get }
    func setupSculpture(model: SculptureModel)
    func setZIndex(index: Double)
    func tapSculpture()
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
        currentSculptureNode = SKSpriteNode(imageNamed: model.name)
        currentSculptureNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * model.xPosition,
            y: GameConstant.sculptureHeightSize * model.yPosition
        )
        currentSculptureNode.name = "sculpture"
        currentSculptureNode.zPosition = 10.0 - model.yPosition * 5.0
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
        let bubbleWidth: CGFloat = 120
        let bubbleHeight: CGFloat = 60
        let bubble = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 10)
        bubble.name = "menu_bubble"
        bubble.fillColor = .white
        bubble.strokeColor = .black
        bubble.lineWidth = 2
        bubble.zPosition = 100
        bubble.position = CGPoint(x: 0, y: currentSculptureNode.size.height + 40)
        
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

extension SculptureManager: SculptureManagerProtocol {
    
    func tapSculpture() {
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

extension SculptureManager: UpdatePositionProtocol {
    var node: SKSpriteNode {
        currentSculptureNode
    }
    
    func startChange() {
        currentSculptureNode.color = .clickableText
        currentSculptureNode.colorBlendFactor = 0.9
    }
    
    func horizontalChange(direction: HorizontalDirection) {
        switch direction {
        case .right:
            self.sculptureModel?.xPosition += 0.01
        case .left:
            self.sculptureModel?.xPosition -= 0.01
        }
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * (self.sculptureModel?.xPosition ?? 0),
            y: GameConstant.sculptureHeightSize * (self.sculptureModel?.yPosition ?? 0)
        )
    }
    
    func verticalChange(direction: VerticalDirection) {
        switch direction {
        case .up:
            self.sculptureModel?.yPosition += 0.01
        case .down:
            self.sculptureModel?.yPosition -= 0.01
        }
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * (self.sculptureModel?.xPosition ?? 0),
            y: GameConstant.sculptureHeightSize * (self.sculptureModel?.yPosition ?? 0)
        )
    }
    
    func removeChange(x: CGFloat, y: CGFloat) {
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * x,
            y: GameConstant.sculptureHeightSize * y
        )
    }
}
