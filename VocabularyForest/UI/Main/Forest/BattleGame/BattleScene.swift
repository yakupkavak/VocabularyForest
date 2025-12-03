//
//  BattleScene.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SpriteKit

protocol BattleSceneProtocol: AnyObject {
    func playerDead()
    func roundComplete()
    func playerWon()
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
    private var touchEnable = false
    
    // MARK: - LIFECYCLE
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        environmentManager = BattleEnvironmentManager(scene: self)
        playerManager = GamePlayerManager(scene: self)
        enemyManager = BattleEnemyManager(scene: self)
        environmentManager.setupEnvironment()
        playerManager.setupPlayer()
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if ((firstBody.categoryBitMask & PhysicsCategory.enemy != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.blackHole != 0)) {
            helper?.roundComplete()
        }
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
    }
    
    private func handleMovementCoordination() {
        let direction = playerManager.direction
        let playerNode = playerManager.playerNode
        let halfPlayerWidth = playerNode.size.width / 2
        let playerX = playerNode.position.x
        
        if playerManager.isMoving {
            let canScrollLeft = direction == .left && playerX < halfPlayerWidth
            let canScrollRight = direction == .right && playerX > self.size.width - halfPlayerWidth
            
            if (direction == .left && canScrollLeft) ||
               (direction == .right && canScrollRight) {
                playerManager.stopPhysicalMovement()
                return
            }
        }
    }
    
    // MARK: - TOUCH EVENTS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchEnable {
            isTouching = true
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let nodesAtPoint = nodes(at: location)
            let direction: GameDirection = (location.x > self.size.width / 2) ? .right : .left
            playerManager.startWalking(direction: direction)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchEnable {
            isTouching = false
            playerManager.stopWalking()
        }
    }
}

// MARK: - VIEW MODEL OUTPUT

extension BattleScene: BattleViewModelOutputProcotol {
    
    func setupNextEnemy() {
        environmentManager?.nextBackground()
        environmentManager?.hideGate()
        playerManager?.setupPlayer()
        enemyManager?.spawnNextEnemy()
        touchEnable = false
    }

    func setupGame(enemyCharacterModels: [EnemyCharacterModel]) {
        enemyManager?.setupEnemyManager(models: enemyCharacterModels)
    }
    
    func correctAnswer() {
        environmentManager?.correctAnswer()
    }
    
    func wrongAnswer() {
        environmentManager?.wrongAnswer()
    }
    
    func enemyAttack() {
        let playerPosition = playerManager.playerNode.position
        enemyManager.enemyAtacks(endPointX: CGFloat(playerPosition.x)) { [weak self] in
            guard let self else { return }
            self.playerManager.die {
                self.helper?.playerDead()
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
                self.enemyManager.killEnemy { [weak self] isBossDead in
                    guard let self else { return }
                    if isBossDead {
                        helper?.playerWon()
                        touchEnable = false
                    }else {
                        environmentManager?.showGate()
                        touchEnable = true
                    }
                }
            }
        }
    }
}
