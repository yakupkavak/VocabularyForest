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
}

class SculptureManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
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
        scene?.addChild(currentSculptureNode)
    }
}

extension SculptureManager: SculptureManagerProtocol {
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
