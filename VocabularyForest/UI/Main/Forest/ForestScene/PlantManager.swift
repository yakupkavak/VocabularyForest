// MARK: - PlantManager.swift

//
//  PlantManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.12.2025.
//

import SpriteKit

protocol PlantManagerProtocol: UpdatePositionProtocol, TapComponentProtocol, TalkProtocol {
    var model: TreeModel? { get }
    func setupPlant(model: TreeModel)
    func growPlant()
    func decreasePlant()
    func fadePlant()
    func perishPlant()
    func recoverPlant()
}

// MARK: - CONSTANTS

extension PlantManager {
    enum Constants {
        static let zero: CGFloat = 0.0
        static let firstFrameIndex: Int = 0
        static let secondFrameIndex: Int = 1
        
        static let anchorPointX: CGFloat = 0.5
        static let anchorPointY: CGFloat = 0.0
        static let fallbackMultiplier: CGFloat = 0.0
        static let screenWidthDivider: CGFloat = 2.0
        
        static let baseZPosition: Double = 10.0
        static let zPositionMultiplier: Double = 20.0
        
        static let defaultColorBlendFactor: CGFloat = 0.0
        static let selectedColorBlendFactor: CGFloat = 0.9
        static let fadedColorBlendFactor: CGFloat = 0.4
        static let perishedColorBlendFactor: CGFloat = 0.8
        
        static let bubbleScaleTarget: CGFloat = 1.0
        static let bubbleScaleInitial: CGFloat = 0.0
        static let bubbleScaleDuration: TimeInterval = 0.2
        static let bubbleRemoveScaleTarget: CGFloat = 0.0
        static let bubbleRemoveDuration: TimeInterval = 0.1
    }
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
        switch model.assetSource {
        case .appAssets:
            let atlas = SKTextureAtlas(named: model.assetName)
            for i in Constants.firstFrameIndex..<atlas.textureNames.count {
                textures.append(atlas.textureNamed("\(model.assetName.lowercased())_\(i)"))
            }
        case .offlineStorage:
            textures = loadOfflineTextures(assetName: model.assetName)
        }
        setPlant(model: model)
        plant.zPosition = getZIndex(yPosition: model.yPosition)
    }
    
    /// Zip ile inen asset'ler `OfflineGameAssets/{assetName}/` klasöründe kare kare,
    /// tekil remote görseller ise `OfflineGameAssets/{assetName}.png` olarak durur.
    func loadOfflineTextures(assetName: String) -> [SKTexture] {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return [] }
        let baseURL = appSupport.appendingPathComponent("OfflineGameAssets")
        let bundleURL = baseURL.appendingPathComponent(assetName)
        
        var frameURLs: [URL]
        if let contents = try? FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil) {
            frameURLs = contents
                .filter { $0.pathExtension.lowercased() == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        } else {
            frameURLs = [baseURL.appendingPathComponent("\(assetName).png")]
        }
        
        return frameURLs.compactMap { url in
            guard let image = UIImage(contentsOfFile: url.path) else { return nil }
            return SKTexture(image: image)
        }
    }
    
    func setPlant(model: TreeModel) {
        // FUTURE: - GROW PLANT
        plant.removeFromParent()
        guard let firstFrame = textures[safe: Constants.secondFrameIndex] ?? textures.first, let scene else {
            return
        }
        plant.texture = firstFrame
        // TODO: - SIZE
        let originalSize = firstFrame.size()
        if originalSize.height > Constants.zero {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = ComponentSizeConstant.plantHeight * aspectRatio
            plant.size = CGSize(width: targetWidth, height: ComponentSizeConstant.plantHeight)
        }
        plant.anchorPoint = CGPoint(x: Constants.anchorPointX, y: Constants.anchorPointY)
        plant.position = CGPoint(
            x: GameConstant.gameWidthSize * model.xPosition,
            y: GameConstant.materialHeightSize * model.yPosition
        )
        plant.name = "plant"
        plant.zPosition = Constants.baseZPosition - model.yPosition * Constants.zPositionMultiplier
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
        let finalName = displayName ?? String(localized: "Bitki")
        
        let bubble = ComponentBubble.createSculptureMenuBubble(parentSize: plant.size, displayName: finalName)
        
        bubble.setScale(Constants.bubbleScaleInitial)
        plant.addChild(bubble)
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

// MARK: - UPDATE POSITION PROTOCOL

extension PlantManager: UpdatePositionProtocol {
    
    func confirmeChange() {
        if isPerished {
            perishPlant()
        } else {
            plant.color = .white
            plant.colorBlendFactor = Constants.defaultColorBlendFactor
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
            x: (GameConstant.gameWidthSize * (self.treeModel?.xPosition ?? Constants.fallbackMultiplier)) + scrollOffset,
            y: GameConstant.materialHeightSize * (self.treeModel?.yPosition ?? Constants.fallbackMultiplier)
        )
    }
    
    func startPositionChange() {
        plant.color = .clickableText
        plant.colorBlendFactor = Constants.selectedColorBlendFactor
    }

    func removeChange(x: CGFloat, y: CGFloat) {
        let scrollOffset = getScrollOffset()
        plant.position = CGPoint(
            x: (GameConstant.gameWidthSize * x) + scrollOffset,
            y: GameConstant.materialHeightSize * y
        )
        self.treeModel?.xPosition = x
        self.treeModel?.yPosition = y
        plant.zPosition = getZIndex(yPosition: y)
        plant.color = .white
        plant.colorBlendFactor = Constants.defaultColorBlendFactor
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
        guard let secondFrame = textures[safe: Constants.secondFrameIndex] else {
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
        plant.colorBlendFactor = Constants.fadedColorBlendFactor
    }
    
    func perishPlant() {
        plant.color = .brown
        plant.colorBlendFactor = Constants.perishedColorBlendFactor
        isPerished = true
    }
    
    func recoverPlant() {
        isPerished = false
        plant.color = .white
        plant.colorBlendFactor = Constants.defaultColorBlendFactor
    }
}

// MARK: - TALK PROTOCOL

extension PlantManager: TalkProtocol {
    
    func talk(text: String) {
        if let existingBubble = plant.childNode(withName: "talk_bubble") {
            existingBubble.removeFromParent()
        }
        let bubble = ComponentBubble.createTalkBubble(parentSize: plant.size, parentXScale: plant.xScale, text: text)
        plant.addChild(bubble)
    }
    
    func removeBubble() {
        if let menuBubble = plant.childNode(withName: "menu_bubble") {
            menuBubble.run(.sequence([
                .scale(to: Constants.bubbleRemoveScaleTarget, duration: Constants.bubbleRemoveDuration),
                .removeFromParent()
            ]))
            isMenuOpen = false
        }
        
        if let talkBubble = plant.childNode(withName: "talk_bubble") {
            talkBubble.run(.sequence([
                .scale(to: Constants.bubbleRemoveScaleTarget, duration: Constants.bubbleRemoveDuration),
                .removeFromParent()
            ]))
        }
    }
}
