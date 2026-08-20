//
//  ForestScene.swift
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
    func confirmeChange()
}

protocol ForectSceneProtocol: AnyObject {
    func updatePosition(model: ComponentModelProtocol, directionList: [DirectionWithCount])
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
    private var selectedManager: UpdatePositionProtocol? = nil
    private var selectedModel: ComponentModelProtocol? = nil
    private var isAnnouncementClaimable = false
    private weak var marketBubbleNode: SKNode?
    var timer: Timer?
    
    // MARK: - LIFECYCLE
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        environmentManager = EnvironmentManager(scene: self)
        playerManager = PlayerManager(scene: self)
        environmentManager.setupEnvironment()
        playerManager.setupPlayer()
        environmentManager.setAnnouncementClaimable(isAnnouncementClaimable)
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
            let animalNode = animal.node
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
        
        if handleMenuTaps(nodes: nodesAtPoint) { return }
        if handleMarketTap(nodes: nodesAtPoint) { return }
        if handleBubbleButtonTaps(nodes: nodesAtPoint) { return }
        if handleEntityTaps(nodes: nodesAtPoint) { return }
        if handleArrowTaps(nodes: nodesAtPoint) { return }
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
        if nodes.contains(where: { $0.name == "announcementButton" }) {
            forestHelper?.showAnnouncement()
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
        if nodes.contains(where: { $0.name == "market_button" }) {
            forestHelper?.showMarket()
            return true
        }
        return false
    }
    
    func handleMarketTap(nodes: [SKNode]) -> Bool {
        if nodes.contains(where: { $0.name == "btn_open_market" }) {
            marketBubbleNode?.removeFromParent()
            forestHelper?.showMarket()
            return true
        }
        guard let marketNode = nodes.first(where: { $0.name == ForestConstant.marketName }) as? SKSpriteNode else {
            return false
        }
        toggleMarketBubble(on: marketNode)
        return true
    }

    /// Tapping the market building shows an invitation bubble instead of opening the
    /// market outright; the bubble's cart icon is the actual "open" affordance.
    func toggleMarketBubble(on marketNode: SKSpriteNode) {
        if let bubble = marketBubbleNode {
            bubble.removeFromParent()
            return
        }

        let bubble = ComponentBubble.createMarketMenuBubble(parentSize: marketNode.size)
        bubble.setScale(ComponentBubble.Constants.initialScale)
        marketNode.addChild(bubble)
        bubble.run(.scale(to: ComponentBubble.Constants.targetScale, duration: ComponentBubble.Constants.scaleDuration))
        marketBubbleNode = bubble

        ComponentBubble.applyAutoCloseAnimation(to: bubble) { }
    }

    func handleBubbleButtonTaps(nodes: [SKNode]) -> Bool {
        guard let btnNode = nodes.first(where: { $0.name == "btn_update_name" || $0.name == "btn_update_pos" }),
              let bubble = btnNode.parent,
              let targetNode = bubble.parent as? SKSpriteNode,
              let buttonName = btnNode.name else {
            return false
        }
        
        if let manager = plantManagers.first(where: { $0.node === targetNode }) {
            guard let model = manager.model else { return false }
            handleBubbleAction(manager: manager ,nameModel: model, generalModel: model, buttonName: buttonName, type: .plant)
            return true
        }
        
        if let manager = animalManagers.first(where: { $0.node === targetNode }) {
            guard let model = manager.model else { return false }
            handleBubbleAction(manager: nil, nameModel: model, generalModel: model, buttonName: buttonName, type: .animal)
            return true
        }
        
        if let manager = sculptureManagers.first(where: { $0.sculptureNode === targetNode }) {
            guard let model = manager.model else { return false }
            handleBubbleAction(manager: manager ,nameModel: model, generalModel: model, buttonName: buttonName, type: .sculpture)
            return true
        }
        return false
    }
    
    func handleBubbleAction(manager: UpdatePositionProtocol?, nameModel: ComponentNameable,generalModel: ComponentModelProtocol ,buttonName: String, type: ComponentType) {
        switch buttonName {
        case "btn_update_name":
            forestHelper?.updateComponentName(model: nameModel, type: type)
        case "btn_update_pos":
            if let manager {
                selectedManager = manager
                selectedModel = generalModel
                environmentManager.showPositionArrows()
                manager.startPositionChange()
            }
        default:
            break
        }
    }

    func handleEntityTaps(nodes: [SKNode]) -> Bool {
        guard let clickedNode = nodes.first(where: { ["plant", "Animal", "sculpture"].contains($0.name) }) as? SKSpriteNode else {
            return false
        }
        
        if let manager = plantManagers.first(where: { $0.node === clickedNode }) {
            manager.tapComponent()
            return true
        }
        if let manager = animalManagers.first(where: { $0.node === clickedNode }) {
            manager.tapComponent()
            return true
        }
        if let manager = sculptureManagers.first(where: { $0.sculptureNode === clickedNode }) {
            manager.tapComponent()
            return true
        }
        
        return false
    }
    
    func handleArrowTaps(nodes: [SKNode]) -> Bool {
        guard let btnNode = nodes.first(where: { ForestConstant.allButtons.contains($0.name ?? "") })
        else {
            return false
        }
        guard let selectedModel else { return false }
        
        if btnNode.name == ForestConstant.confirmIconName {
            helper?.updatePosition(model: selectedModel, directionList: previewDirectionList)
            selectedManager?.confirmeChange()
            clearSelection()
        }else if btnNode.name == ForestConstant.refuseIconName {
            selectedManager?.removeChange(
                x: selectedModel.xPosition,
                y: selectedModel.yPosition
            )
            clearSelection()
        }else if btnNode.name == ForestConstant.rightIconName {
            updateDirectionList(.right)
        }else if btnNode.name == ForestConstant.leftIconName {
            updateDirectionList(.left)
        }else if btnNode.name == ForestConstant.upIconName {
            updateDirectionList(.up)
        }else if btnNode.name == ForestConstant.downIconName {
            updateDirectionList(.down)
        }else {
            return false
        }
        return true
    }
    
    func updateDirectionList(_ direction: Directions) {
        if let index = previewDirectionList.firstIndex(where: { $0.direction == direction}) {
            previewDirectionList[index].count += 1
        }else {
            previewDirectionList.append(DirectionWithCount(direction: direction, count: 1))
        }
        selectedManager?.positionChange(direction: direction)
    }
    
    func clearSelection() {
        selectedManager = nil
        selectedModel = nil
        previewDirectionList = []
        environmentManager?.closePositionArrows()
    }

}

// MARK: - VIEW MODEL OUTPUT

extension ForestScene: ForestViewModelOutputProcotol {
    
    func updateAnnouncementClaimable(_ isClaimable: Bool) {
        isAnnouncementClaimable = isClaimable
        environmentManager?.setAnnouncementClaimable(isClaimable)
    }
    
    func talkComponent(type model: ComponentType, id: UUID, message: String) {
        switch model {
        case .animal:
            if let animal = animalManagers.first(where: { $0.model?.id == id }) {
                animal.talk(text: message)
            }
            
        case .plant:
            if let plant = plantManagers.first(where: { $0.model?.id == id }) {
                plant.talk(text: message)
            }
            
        case .sculpture:
            if let sculpture = sculptureManagers.first(where: { $0.model?.id == id }){
                sculpture.talk(text: message)
            }
        }
    }
    
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
            if let model = sculptureManager.model, model.id == sculpture.id {
                sculptureManager.updateName(name: sculpture.characterName)
                return
            }
        }
        let manager = SculptureManager(scene: self)
        manager.setupSculpture(model: sculpture)
        sculptureManagers.append(manager)
    }
    
    func setupPlant(plant: TreeModel) {
        for plantManager in self.plantManagers {
            if let model = plantManager.model, model.id == plant.id {
                plantManager.updateName(name: plant.characterName)
                return
            }
        }
        let manager = PlantManager(scene: self)
        manager.setupPlant(model: plant)
        plantManagers.append(manager)
    }
    
    func setupAnimal(animal: AnimalModel?){
        guard let animal else { return }
        for animalManager in self.animalManagers {
            if let model = animalManager.model, model.id == animal.id {
                animalManager.updateName(name: animal.characterName)
                return
            }
        }
        let animalManager = AnimalManager(scene: self)
        animalManager.setupAnimalManager(model: animal)
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
