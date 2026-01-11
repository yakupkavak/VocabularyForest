//
//  PlantManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.12.2025.
//

import SpriteKit

protocol PlantManagerProtocol {
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
        guard let firstFrame = textures.first, let scene else {
            return
        }
        plant.texture = firstFrame
        // TODO: - SIZE
        let originalSize = firstFrame.size()
        if originalSize.height > 0 {
            let aspectRatio = originalSize.width / originalSize.height
            let targetWidth = GameConstant.plantHeightSize * aspectRatio
            plant.size = CGSize(width: targetWidth, height: GameConstant.plantHeightSize)
        }
        plant.anchorPoint = CGPoint(x: 0.5, y: 0)
        plant.position = CGPoint(
            x: GameConstant.gameWidthSize * model.treeXPosition,
            y: GameConstant.materialHeightSize * model.treeYPosition
        )
        plant.name = model.treeName
        plant.zPosition = 5 - model.treeYPosition * 3.0
        scene.addChild(plant)
    }
}

// MARK: - PLANT MANAGER PROTOCOL

extension PlantManager: PlantManagerProtocol {
    
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
