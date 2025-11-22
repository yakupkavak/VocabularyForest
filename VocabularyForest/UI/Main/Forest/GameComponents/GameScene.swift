//
//  GameScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SpriteKit
import SwiftUI
import AVFoundation

enum GameConstant {
    static let movingCharacterAnimation = "movingCharacterAnimation"
    static let movingCharacterAction = "movingCharacterAction"
    static let backgroundAction = "backgroundAnimation"
    static let airAction = "airAnimation"
    static let movingDistance: CGFloat = 100
    static let movingTimePerFrame: CGFloat = 0.1
    static let gameWidthSize = UIScreen.main.bounds.width * CGFloat(4)
    static let gameHeightSize = UIScreen.main.bounds.height
    static let floorHeightSize = UIScreen.main.bounds.height * CGFloat(0.4)
}

enum GameDirection {
    case right
    case left
}

protocol GameSceneProtocol: AnyObject {
    func getTrees() -> Resource<[Tree]>
    func getAnimals() -> Resource<[Animal]>
    func getSculptures() -> Resource<[Sculpture]>
    func getQuests() -> Resource <[QuestModel]>
    func treeOnClick(id: UUID)
    func getForestStatus() -> Resource<ForestStatusModel>
    func updateForestStatus(model: ForestStatusModel)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - PROPERTIES

    var playerManager: PlayerManagerProtocol!
    var envManager: EnvironmentManagerProtocol!
    var helper: GameSceneProtocol?
    private var isTouching = false
    
    // MARK: - LIFECYCLE
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        envManager = EnvironmentManager(scene: self)
        playerManager = PlayerManager(scene: self)
        envManager.setupEnvironment()
        playerManager.setupPlayer()
    }
    
    override func update(_ currentTime: TimeInterval) {
        envManager.update()
        guard isTouching else { return }
        handleMovementCoordination()
    }
    
    // MARK: - LOGIC
    
    private func handleMovementCoordination() {
        let direction = playerManager.direction
        let floor = envManager.floorNode
        let playerNode = playerManager.playerNode
        
        let centerScreen = self.size.width / 2
        let halfPlayerWidth = playerNode.size.width / 2
        let playerX = playerNode.position.x
        if playerManager.isMoving {
            let canScrollLeft = direction == .left && floor.frame.minX < 0
            let canScrollRight = direction == .right && floor.frame.maxX > self.size.width
            
            if (direction == .left && playerX <= centerScreen && canScrollLeft) ||
               (direction == .right && playerX >= centerScreen && canScrollRight) {
                playerManager.stopPhysicalMovement()
                playerNode.position.x = centerScreen
                envManager.moveBackground(direction: direction)
                return
            }
        }
        if direction == .right && floor.frame.maxX <= self.size.width {
            if playerX >= self.size.width - halfPlayerWidth {
                playerManager.stopPhysicalMovement()
            } else {
                envManager.stopBackground()
                playerManager.startWalking(direction: .right)
            }
        }
        else if direction == .left && floor.frame.minX >= 0 {
            if playerX <= halfPlayerWidth {
                playerManager.stopPhysicalMovement()
            } else {
                envManager.stopBackground()
                playerManager.startWalking(direction: .left)
            }
        }
    }
    
    // MARK: - TOUCH EVENTS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = true
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let direction: GameDirection = (location.x > self.size.width / 2) ? .right : .left
        playerManager.startWalking(direction: direction)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        playerManager.stopWalking()
        envManager.stopBackground()
    }
}

// MARK: - VIEW MODEL OUTPUT

extension GameScene: ForestViewModelOutputProcotol {
    func startRain() {
        print("Scene: Yağmur efekti başlatılıyor...")
    }
    
    func stopRain() {
        print("Scene: Yağmur durdu.")
    }
}
