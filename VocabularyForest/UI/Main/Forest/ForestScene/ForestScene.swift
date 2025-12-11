//
//  GameScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SpriteKit
import SwiftUI
import AVFoundation

protocol ForectSceneProtocol: AnyObject {
    func getTrees() -> Resource<[Tree]>
    func getSculptures() -> Resource<[Sculpture]>
    func getQuests() -> Resource <[QuestModel]>
    func treeOnClick(id: UUID)
    func getForestStatus() -> Resource<ForestStatusModel>
    func updateForestStatus(model: ForestStatusModel)
}

class ForestScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - PROPERTIES
    
    var playerManager: PlayerManagerProtocol!
    var environmentManager: EnvironmentManagerProtocol!
    var forestHelper: ForestUIProtocol?
    var helper: ForectSceneProtocol?
    var animalManagers: [AnimalManagerProtocol] = []
    private var isTouching = false
    var timer: Timer?
    
    // MARK: - LIFECYCLE
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        environmentManager = EnvironmentManager(scene: self)
        playerManager = PlayerManager(scene: self)
        environmentManager.setupEnvironment()
        playerManager.setupPlayer()
    }
    
    override func update(_ currentTime: TimeInterval) {
        environmentManager.update()
        handleAnimalsCoordination()
        guard isTouching else { return }
        handlePlayerCoordination()
    }
    
    // MARK: - LOGIC
    
    private func handlePlayerCoordination() {
        let direction = playerManager.direction
        let floor = environmentManager.floorNode
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
                environmentManager.moveBackground(direction: direction)
                return
            }
        }
        if direction == .right && floor.frame.maxX <= self.size.width {
            if playerX >= self.size.width - halfPlayerWidth {
                playerManager.stopPhysicalMovement()
            } else {
                environmentManager.stopBackground()
                playerManager.startWalking(direction: .right)
            }
        }
        else if direction == .left && floor.frame.minX >= 0 {
            if playerX <= halfPlayerWidth {
                playerManager.stopPhysicalMovement()
            } else {
                environmentManager.stopBackground()
                playerManager.startWalking(direction: .left)
            }
        }
    }
    
    private func handleAnimalsCoordination() {
        if animalManagers.isEmpty {
            return
        }
        
        for animal in animalManagers {
            let animalNode = animal.animalNode
            let floor = environmentManager.floorNode
            let animalX = animalNode.position.x
            let halfAnimalWidth = animalNode.size.width / 2
            let floorMinX = floor.frame.minX
            let floorMaxX = floor.frame.maxX
            
            if animal.animalDirection == .right {
                if animalX >= floorMaxX - halfAnimalWidth {
                    animal.changeDirection()
                }
            }
            else if animal.animalDirection == .left {
                if animalX <= floorMinX + halfAnimalWidth {
                    animal.changeDirection()
                }
            }
        }
    }
    
    // MARK: - TOUCH EVENTS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = true
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)
        if nodesAtPoint.contains(where: { $0.name == "menu_button" }) {
            forestHelper?.showOptions()
            return
        }
        if nodesAtPoint.contains(where: { $0.name == "quest_button" }) {
            forestHelper?.showQuests()
            return
        }
        if nodesAtPoint.contains(where: { $0.name == "play_button" }) {
            forestHelper?.showGameSelection()
            return
        }
        if nodesAtPoint.contains(where: { $0.name == "forest_button" }) {
            forestHelper?.showForestInfo()
            return
        }
        let direction: GameDirection = (location.x > self.size.width / 2) ? .right : .left
        playerManager.startWalking(direction: direction)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        playerManager.stopWalking()
        environmentManager.stopBackground()
    }
}

// MARK: - VIEW MODEL OUTPUT

extension ForestScene: ForestViewModelOutputProcotol {
    func setupAnimals(animals: AnimalModel?){
        guard let animals else { return }
        let animalManager = AnimalManager(scene: self)
        animalManager.setupAnimalManager(model: animals)
        animalManagers.append(animalManager)
    }
    
    func startRain() {
        environmentManager.startRain()
    }
    
    func stopRain() {
        print("Scene: Yağmur durdu.")
    }
}
