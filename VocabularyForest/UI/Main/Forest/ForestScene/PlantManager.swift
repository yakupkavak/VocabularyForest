//
//  PlantManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.12.2025.
//

import SpriteKit

protocol ComponentSelectProtocol {
    func updateName()
    func updatePosition()
}

protocol PlantManagerProtocol {
    var plantNode: SKSpriteNode { get }
    func setupPlant(model: TreeModel)
    func growPlant()
    func decreasePlant()
    func fadePlant()
    func perishPlant()
    func recoverPlant()
    func tapPlant()
    func handleMenuAction(nodeName: String)
}

class PlantManager {
    
    // MARK: - PROPERTIES
    
    var plant = SKSpriteNode()
    var output: ComponentSelectProtocol?
    private var isMenuOpen = false
    private weak var scene: SKScene?
    private var textures: [SKTexture] = []
    
    // MARK: - INIT
    
    init(scene: SKScene? = nil) {
        self.scene = scene
    }
}

// MARK: - HELPERS

private extension PlantManager {
    
    func loadTextures(for model: TreeModel) {
        let atlas = SKTextureAtlas(named: model.treeName)
        for i in 0..<atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(model.treeName.lowercased())_\(i)"))
        }
        setPlant(model: model)
    }
    
    func setPlant(model: TreeModel) {
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
            x: GameConstant.gameWidthSize * model.treeXPosition,
            y: GameConstant.materialHeightSize * model.treeYPosition
        )
        plant.name = "plant"
        plant.zPosition = 10 - model.treeYPosition * 20.0
        scene.addChild(plant)
    }
    
    func createInteractionBubble() {
        if let existingBubble = plant.childNode(withName: "menu_bubble") {
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
        bubble.position = CGPoint(x: 0, y: plant.size.height + 40)
        
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
        if let bubble = plant.childNode(withName: "menu_bubble") {
            bubble.run(.sequence([
                .scale(to: 0, duration: 0.1),
                .removeFromParent()
            ]))
            isMenuOpen = false
        }
    }
}

// MARK: - PLANT MANAGER PROTOCOL

extension PlantManager: PlantManagerProtocol {
    
    var plantNode: SKSpriteNode {
        plant
    }
    
    func handleMenuAction(nodeName: String) {
        // Balonu kapat
        removeBubble()
        
        // Hangi butona basıldıysa delegate'e (ViewModel/SwiftUI) haber ver
        if nodeName == "btn_update_name" {
            print("İsim güncelleme istendi")
            output?.updateName()
        } else if nodeName == "btn_update_pos" {
            print("Pozisyon güncelleme istendi")
            output?.updatePosition()
        }
    }
    
    func tapPlant() {
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
    }
    
    func recoverPlant() {
        plant.colorBlendFactor = 0.0
    }
}

extension PlantManager: TalkProtocol {
    var node: SKSpriteNode {
        plant
    }
    
    func talk(text: String) {
        print("")
    }
}
