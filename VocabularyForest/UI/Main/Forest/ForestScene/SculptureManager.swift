// MARK: - SculptureManager.swift

//
//  SculptureManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.12.2025.
//

import SpriteKit

protocol TapComponentProtocol {
    func tapComponent()
    func updateName(name: String)
}

protocol SculptureManagerProtocol: AnyObject, UpdatePositionProtocol, TapComponentProtocol, TalkProtocol {
    var sculptureNode: SKSpriteNode { get }
    var model: SculptureModel? { get }
    func setupSculpture(model: SculptureModel)
    func setZIndex(index: Double)
}

// MARK: - CONSTANTS

extension SculptureManager {
    enum Constants {
        static let zero: CGFloat = 0.0
        static let anchorPointX: CGFloat = 0.5
        static let anchorPointY: CGFloat = 0.0
        static let fallbackMultiplier: CGFloat = 0.0
        static let selectedColorBlendFactor: CGFloat = 0.9
        static let defaultColorBlendFactor: CGFloat = 0.0
        static let screenWidthDivider: CGFloat = 2.0
        
        static let bubbleScaleTarget: CGFloat = 1.0
        static let bubbleScaleInitial: CGFloat = 0.0
        static let bubbleScaleDuration: TimeInterval = 0.2
        static let bubbleRemoveScaleTarget: CGFloat = 0.0
        static let bubbleRemoveDuration: TimeInterval = 0.1
    }
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
        switch model.assetSource {
        case .appAssets:
            currentSculptureNode = SKSpriteNode(imageNamed: model.assetName)
        case .offlineStorage:
            guard let texture = loadOfflineTexture(assetName: model.assetName) else { return }
            currentSculptureNode = SKSpriteNode(texture: texture)
        }
        currentSculptureNode.anchorPoint = CGPoint(x: Constants.anchorPointX, y: Constants.anchorPointY)
        currentSculptureNode.position = CGPoint(
            x: GameConstant.gameWidthSize * model.xPosition,
            y: GameConstant.sculptureHeightSize * model.yPosition
        )
        let originalSize = currentSculptureNode.size
        if originalSize.height > Constants.zero {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = ComponentSizeConstant.plantHeight * aspectRatio
            currentSculptureNode.size = CGSize(width: targetWidth, height: ComponentSizeConstant.sculptureHeight)
        }
        currentSculptureNode.name = "sculpture"
        currentSculptureNode.zPosition = getZIndex(yPosition: model.yPosition)
        sculptureModel = model
        scene?.addChild(currentSculptureNode)
    }
    
    func loadOfflineTexture(assetName: String) -> SKTexture? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let baseURL = appSupport.appendingPathComponent("OfflineGameAssets")
        var fileURL = baseURL.appendingPathComponent("\(assetName).png")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let bundleURL = baseURL.appendingPathComponent(assetName)
            guard let firstFrame = (try? FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil))?
                .filter({ $0.pathExtension.lowercased() == "png" })
                .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                .first else { return nil }
            fileURL = firstFrame
        }
        
        guard let image = UIImage(contentsOfFile: fileURL.path) else { return nil }
        return SKTexture(image: image)
    }
     
    func createInteractionBubble() {
        if let existingBubble = currentSculptureNode.childNode(withName: "menu_bubble") {
            existingBubble.removeFromParent()
            isMenuOpen = false
            return
        }
        
        isMenuOpen = true
        let displayName = sculptureModel?.characterName.isEmpty == false ? sculptureModel?.characterName : sculptureModel?.assetName
        
        let bubble = ComponentBubble.createSculptureMenuBubble(parentSize: currentSculptureNode.size, displayName: displayName)
        
        bubble.setScale(Constants.bubbleScaleInitial)
        currentSculptureNode.addChild(bubble)
        bubble.run(.scale(to: Constants.bubbleScaleTarget, duration: Constants.bubbleScaleDuration))
        
        ComponentBubble.applyAutoCloseAnimation(to: bubble) { [weak self] in
            self?.isMenuOpen = false
        }
    }
    
    func getScrollOffset() -> CGFloat {
        guard let scene = scene,
              let floor = scene.childNode(withName: ForestConstant.floorName) else { return Constants.zero }
        let initialX = scene.size.width / Constants.screenWidthDivider
        return floor.position.x - initialX
    }
}

// MARK: - SCULPTURE MANAGER PROTOCOL

extension SculptureManager: SculptureManagerProtocol {
    
    func updateName(name: String) {
        sculptureModel?.characterName = name
    }
    
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
        currentSculptureNode.colorBlendFactor = Constants.defaultColorBlendFactor
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
        let scrollOffset = getScrollOffset()
        if let yPosition = self.sculptureModel?.yPosition {
             currentSculptureNode.zPosition = getZIndex(yPosition: yPosition)
        }
        currentSculptureNode.position = CGPoint(
            x: (GameConstant.gameWidthSize * (self.sculptureModel?.xPosition ?? Constants.fallbackMultiplier)) + scrollOffset,
            y: GameConstant.sculptureHeightSize * (self.sculptureModel?.yPosition ?? Constants.fallbackMultiplier)
        )
    }
    
    var node: SKSpriteNode {
        currentSculptureNode
    }
    
    func startPositionChange() {
        currentSculptureNode.color = .clickableText
        currentSculptureNode.colorBlendFactor = Constants.selectedColorBlendFactor
    }

    func removeChange(x: CGFloat, y: CGFloat) {
        let scrollOffset = getScrollOffset()
        currentSculptureNode.position = CGPoint(
            x: (GameConstant.gameWidthSize * x) + scrollOffset,
            y: GameConstant.sculptureHeightSize * y
        )
        self.sculptureModel?.xPosition = x
        self.sculptureModel?.yPosition = y
        currentSculptureNode.zPosition = getZIndex(yPosition: y)
        currentSculptureNode.color = .white
        currentSculptureNode.colorBlendFactor = Constants.defaultColorBlendFactor
    }
}

// MARK: - TALK PROTOCOL

extension SculptureManager: TalkProtocol {
    
    func talk(text: String) {
        if let existingBubble = currentSculptureNode.childNode(withName: "talk_bubble") {
            existingBubble.removeFromParent()
        }
        let bubble = ComponentBubble.createTalkBubble(parentSize: currentSculptureNode.size, parentXScale: currentSculptureNode.xScale, text: text)
        currentSculptureNode.addChild(bubble)
    }
    
    func removeBubble() {
        if let bubble = currentSculptureNode.childNode(withName: "menu_bubble") {
            bubble.run(.sequence([
                .scale(to: Constants.bubbleRemoveScaleTarget, duration: Constants.bubbleRemoveDuration),
                .removeFromParent()
            ]))
            isMenuOpen = false
        }
    }
}
