//
//  GameScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.11.2025.
//

import SpriteKit
import SwiftUI
import AVFoundation

protocol ShowClickable: AnyObject {
    func showButton()
}

protocol TalkProtocol: AnyObject {
    var node: SKSpriteNode { get }
    func talk(text: String)
    func removeBubble()
}

protocol UpdatePositionProtocol: AnyObject {
    var node: SKSpriteNode { get }
    func startPositionChange()
    func positionChange(direction: Directions)
    func removeChange(x: CGFloat, y: CGFloat)
}

protocol ForectSceneProtocol: AnyObject {
    func updatePosition(uuid: UUID, for componentType: ComponentType, directionList: [DirectionWithCount])
}

class ForestScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - PROPERTIES
    
    var playerManager: PlayerManagerProtocol!
    var environmentManager: EnvironmentManagerProtocol!
    var forestHelper: ForestUIProtocol?
    var helper: ForectSceneProtocol?
    var animalManagers: [AnimalManagerProtocol] = []
    var plantManagers: [PlantManagerProtocol] = []
    var sculptureManagers: [SculptureManagerProtocol] = []
    private var isTouching = false
    private var previewDirectionList: [DirectionWithCount] = []
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
        
        if let btnNode = nodesAtPoint.first(where: { $0.name == "btn_update_name" || $0.name == "btn_update_pos" }) {
            if let bubble = btnNode.parent, let targetNode = bubble.parent as? SKSpriteNode {
                if let targetManager = plantManagers.first(where: { $0.plantNode === targetNode }) {
                    guard let name = btnNode.name else { return }
                    switch name {
                    case "btn_update_name":
                        if let model = targetManager.model {
                            forestHelper?.updateComponentName(model: model, type: .plant)
                        }else { return }
                    case "btn_update_pos":
                        targetManager.tapPlant()
                    default:
                        print("unknown post")
                    }
                    return
                }
                if let targetManager = animalManagers.first(where: { $0.animalNode === targetNode }) {
                    guard let name = btnNode.name else { return }
                    switch name {
                    case "btn_update_name":
                        if let model = targetManager.model {
                            forestHelper?.updateComponentName(model: model, type: .animal)
                        }else { return }
                    case "btn_update_pos":
                        targetManager.tapAnimal()
                    default:
                        print("unknown post")
                    }
                    return
                }
                if let targetManager = sculptureManagers.first(where: { $0.sculptureNode === targetNode }) {
                    guard let name = btnNode.name else { return }
                    switch name {
                    case "btn_update_name":
                        if let model = targetManager.model {
                            forestHelper?.updateComponentName(model: model, type: .sculpture)
                        }else { return }
                    case "btn_update_pos":
                        environmentManager.showPositionArrows()
                        targetManager.startPositionChange()
                    default:
                        print("unknown post")
                    }
                    return
                }
            }
        }
        if let clickedNode = nodesAtPoint.first(where: { $0.name == "plant" || $0.name == "animal" || $0.name == "sculpture" }) as? SKSpriteNode {
            if let targetManager = plantManagers.first(where: { $0.plantNode === clickedNode }) {
                targetManager.tapPlant()
                isTouching = false
                return
            }
            if let targetManager = animalManagers.first(where: { $0.animalNode === clickedNode }) {
                targetManager.tapAnimal()
                isTouching = false
                return
            }
            
            if let targetManager = sculptureManagers.first(where: { $0.sculptureNode === clickedNode }) {
                targetManager.tapSculpture()
                isTouching = false
                return
            }
        }
        let direction: HorizontalDirection = (location.x > self.size.width / 2) ? .right : .left
        playerManager.startWalking(direction: direction)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        playerManager.stopWalking()
        environmentManager.stopBackground()
    }
}

// MARK: - PRIVATE HELPER

private extension ForestScene {
    func handleMenuTaps(nodes: [SKNode]) -> Bool {
        if nodes.contains(where: { $0.name == "menu_button" }) {
            forestHelper?.showOptions()
            return true
        }
        if nodes.contains(where: { $0.name == "quest_button" }) {
            forestHelper?.showQuests()
            return true
        }
        if nodes.contains(where: { $0.name == "play_button" }) {
            forestHelper?.showGameSelection()
            return true
        }
        if nodes.contains(where: { $0.name == "forest_button" }) {
            forestHelper?.showForestInfo()
            return true
        }
        return false
    }
    private func handleBubbleButtonTaps(nodes: [SKNode]) -> Bool {
        guard let btnNode = nodes.first(where: { $0.name == "btn_update_name" || $0.name == "btn_update_pos" }),
              let bubble = btnNode.parent,
              let targetNode = bubble.parent as? SKSpriteNode,
              let buttonName = btnNode.name else {
            return false
        }
        
        if let manager = plantManagers.first(where: { $0.plantNode === targetNode }) {
            handleBubbleAction(manager: manager, buttonName: buttonName, type: .plant)
            return true
        }
        
        if let manager = animalManagers.first(where: { $0.animalNode === targetNode }) {
            handleBubbleAction(manager: manager, buttonName: buttonName, type: .animal)
            return true
        }
        
        if let manager = sculptureManagers.first(where: { $0.sculptureNode === targetNode }) {
            if buttonName == "btn_update_pos" {
                environmentManager.showPositionArrows()
                manager.startPositionChange()
            } else {
                handleBubbleAction(manager: manager, buttonName: buttonName, type: .sculpture)
            }
            return true
        }
        return false
    }
    private func handleBubbleAction(manager: any ComponentNameable, buttonName: String, type: ComponentType) {
        // Not: Manager'ların ortak bir protokolü (örn: ComponentNameableManager) olduğunu varsayıyorum.
        // Eğer yoksa burada 'Any' kullanıp cast etmen gerekebilir veya kod tekrarı yapabilirsin.
        
        // Basitlik adına senin switch yapını buraya uyarlıyorum:
        switch buttonName {
        case "btn_update_name":
            if let model = manager.model {
                forestHelper?.updateComponentName(model: model, type: type)
            }
        case "btn_update_pos":
            // Her manager'ın kendi tap/move fonksiyonu var
            if let plantManager = manager as? PlantManager { plantManager.tapPlant() }
            else if let animalManager = manager as? AnimalManager { animalManager.tapAnimal() }
        default:
            break
        }
    }

    private func handleEntityTaps(nodes: [SKNode]) -> Bool {
        // Doğrudan bitki, hayvan veya heykele tıklandı mı?
        guard let clickedNode = nodes.first(where: { ["plant", "animal", "sculpture"].contains($0.name) }) as? SKSpriteNode else {
            return false
        }
        
        if let manager = plantManagers.first(where: { $0.plantNode === clickedNode }) {
            manager.tapPlant()
            return true
        }
        if let manager = animalManagers.first(where: { $0.animalNode === clickedNode }) {
            manager.tapAnimal()
            return true
        }
        if let manager = sculptureManagers.first(where: { $0.sculptureNode === clickedNode }) {
            manager.tapSculpture()
            return true
        }
        
        return false
    }
    
}

// MARK: - VIEW MODEL OUTPUT

extension ForestScene: ForestViewModelOutputProcotol {
    func startFade() {
        for plantManager in self.plantManagers {
            plantManager.fadePlant()
        }
    }
    
    func startDrought() {
        environmentManager.startDrought()
        for animalManager in self.animalManagers {
            animalManager.stopMoving()
        }
        for plantManager in self.plantManagers {
            plantManager.perishPlant()
        }
    }
    
    func finishDrought() {
        environmentManager.finishDrought()
        for animalManager in self.animalManagers {
            animalManager.startMoving()
        }
        for plantManager in self.plantManagers {
            plantManager.recoverPlant()
        }
    }
    
    func setupSculpture(sculpture: SculptureModel) {
        for sculptureManager in self.sculptureManagers {
            if let model = sculptureManager.model, model == sculpture {
                sculptureManager.setupSculpture(model: sculpture)
                return
            }
        }
        let manager = SculptureManager(scene: self)
        manager.setupSculpture(model: sculpture)
        sculptureManagers.append(manager)
    }
    
    func setupPlant(plant: TreeModel) {
        let manager = PlantManager(scene: self)
        manager.setupPlant(model: plant)
        plantManagers.append(manager)
    }
    
    func setupAnimals(animals: AnimalModel?){
        guard let animals else { return }
        let animalManager = AnimalManager(scene: self)
        animalManager.setupAnimalManager(model: animals)
        animalManagers.append(animalManager)
    }
    
    func startRain() {
        environmentManager.startRain()
        finishDrought()
    }
    
    func stopRain() {
        environmentManager.stopRain()
    }
}
