//
//  BattleScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SpriteKit

protocol BattleSceneProtocol: AnyObject {
    func startGame()
    func roundComplete()
}

class BattleScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - PROPERTIES

    var playerManager: GamePlayerManagerProtocol!
    var environmentManager: BattleEnvironmentManagerProtocol!
    var enemyManager: BattleEnemyManagerProtocol!
    var forestHelper: ForestUIProtocol?
    var helper: BattleSceneProtocol?
    private var isTouching = false
    private var isGameStarted = false
    private let startLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var timer: Timer?
    
    // MARK: - LIFECYCLE
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        environmentManager = BattleEnvironmentManager(scene: self)
        playerManager = GamePlayerManager(scene: self)
        enemyManager = BattleEnemyManager(scene: self)
        environmentManager.setupEnvironment()
        playerManager.setupPlayer()
        enemyManager.spawnNewEnemy()
        playerManager.startWaiting()
        forestHelper?.hideOptions()
        var runCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            runCount += 1
            if runCount == 5 {
                //self.enemyAttack()
            }
        })
    }
    
    override func update(_ currentTime: TimeInterval) {
        environmentManager.update()
        guard isTouching else { return }
        handleMovementCoordination()
    }
    
    // MARK: - SETUP UI
    
    private func setupStartButton() {
        startLabel.text = "TAP TO START BATTLE!"
        startLabel.fontSize = 36
        startLabel.fontColor = .yellow
        startLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        startLabel.zPosition = 10
        startLabel.name = "start_button"
        
        let fade = SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.fadeOut(withDuration: 0.5)])
        startLabel.run(SKAction.repeatForever(fade))
        
        addChild(startLabel)
    }
    
    // MARK: - LOGIC
    
    private func startGame() {
        isGameStarted = true
        startLabel.removeFromParent()
        helper?.startGame()
    }
    
    private func handleMovementCoordination() {
        let direction = playerManager.direction
        let floor = environmentManager.backgroundNode
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
    
    // MARK: - TOUCH EVENTS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = true
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)
        if !isGameStarted {
            if nodesAtPoint.contains(where: { $0.name == "start_button" }) {
                startGame()
            }
            return
        }
        if nodesAtPoint.contains(where: { $0.name == "menu_button" }) {
            forestHelper?.showOptions()
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

extension BattleScene: BattleViewModelOutputProcotol {
    func correctAnswer() {
        print("correct answer")
    }
    
    func wrongAnswer() {
        print("wrong answer")
    }
    
    func enemyAttack() {
        let playerPosition = playerManager.playerNode.position
        enemyManager.enemyAtacks(endPoint: CGPoint(x: playerPosition.x + 70, y: playerPosition.y)) { [weak self] in
            guard let self else { return }
            
            self.playerManager.die {
                print("player died")
            }
        }
    }
    
    func startMagic(magic: MagicType) {
        playerManager.startAttack() { [weak self] in
            guard let self = self else { return }
            
            let playerNode = self.playerManager.playerNode
            let enemyNode = self.enemyManager.enemyNode
            let startX = playerNode.position.x + (50)
            let startY = playerNode.position.y + playerNode.size.height * 0.8
            let endX = enemyNode.position.x
            let startPoint = CGPoint(x: startX, y: startY)
            let endPoint = CGPoint(x: endX, y: startY)
            
            self.environmentManager.startMagic(
                magic: magic,
                startPoint: startPoint,
                endPoint: endPoint
            ) {
                self.enemyManager.killEnemy {
                    print("Düşman öldü!")
                }
            }
        }
    }
}
