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
    
    func loadTextures(for name: String) {
        let atlas = SKTextureAtlas(named: name)
        for i in 0..<atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(name.lowercased())_\(i)"))
        }
    }
    
    func setPlant(model: TreeModel) {
        guard let firstFrame = textures.first, let scene else {
            return
        }
        plant.texture = firstFrame
        // TODO: - SIZE
        plant.anchorPoint = CGPoint(x: 0.5, y: 0)
        plant.position = CGPoint(
            x: GameConstant.gameWidthSize * model.treeXPosition,
            y: GameConstant.materialHeightSize * model.treeYPosition
        )
        plant.zPosition = 3
        scene.addChild(plant)
    }
}

// MARK: - PLANT MANAGER PROTOCOL

extension PlantManager: PlantManagerProtocol {
    
    func setupPlant(model: TreeModel) {
        loadTextures(for: model.treeName)
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
    
    func perishPlant() {
        plant.color = .brown
        plant.colorBlendFactor = 0.5
    }
    
    func recoverPlant() {
        plant.colorBlendFactor = 0.0
    }
}
