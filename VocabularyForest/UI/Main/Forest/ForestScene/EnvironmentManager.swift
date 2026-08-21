//
//  EnvironmentManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import SpriteKit

protocol EnvironmentManagerProtocol: AnyObject {
    var floorNode: SKSpriteNode { get }
    func setupEnvironment()
    func moveBackground(direction: HorizontalDirection)
    func stopBackground()
    func update()
    func startRain()
    func stopRain()
    func startDrought()
    func finishDrought()
    func showPositionArrows()
    func closePositionArrows()
    func setAnnouncementClaimable(_ isClaimable: Bool)
}

private extension EnvironmentManager {
    enum Constant {
        static let menuButtonName = "menu_button"
        static let marketIdleTimeMultiplier: Double = 0.8
        static let marketFloorHeightMultiplier: CGFloat = 0.79
        static let scrollSpeedPerSecond: CGFloat = 100
        /// Seconds of rightward scrolling before the market's left edge enters the screen
        static let marketRevealScrollSeconds: CGFloat = 0.5
        /// Sign is on-screen at launch, standing left of the player on the same ground line
        static let announcementSignRelativeX: CGFloat = 0.22
        static let announcementSignFloorHeightMultiplier: CGFloat = 0.80

    }
}
class EnvironmentManager {
    
    // MARK: - PROPERTIES
    
    private weak var scene: SKScene?
    let floorNode = SKSpriteNode(imageNamed: "floor")
    private var skyDecor = SKSpriteNode(imageNamed: "sky_decor")
    private let waterStatue = SKSpriteNode(imageNamed: "water_statue")
    private let grassStatue = SKSpriteNode(imageNamed: "grass_statue")
    private let menuButton = SKSpriteNode(imageNamed: "menu_button")
    private let announcementButton = SKSpriteNode(imageNamed: "announcement_button")
    private let forestButton = SKSpriteNode(imageNamed: "forest_button")
    private let playButton = SKSpriteNode(imageNamed: "play_button")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let rightIcon = SKSpriteNode(imageNamed: "right_icon")
    private let leftIcon = SKSpriteNode(imageNamed: "left_icon")
    private let downIcon = SKSpriteNode(imageNamed: "down_icon")
    private let upIcon = SKSpriteNode(imageNamed: "up_icon")
    private let confirmIcon = SKSpriteNode(imageNamed: "accept_button")
    private let refuseIcon = SKSpriteNode(imageNamed: "close_button")
    private var icons: [SKSpriteNode] = []
    private var marketTextures: [SKTexture] = []
    private let marketNode = SKSpriteNode()
    private let announcementSignNode = SKSpriteNode(imageNamed: "announcement_sign")
    private var announcementBadgeNode: SKShapeNode?

    private var isRaining = false
    
    // MARK: - INIT
    
    init(scene: SKScene) {
        self.scene = scene
        icons = [rightIcon, leftIcon, upIcon, downIcon, confirmIcon, refuseIcon]
    }
}

// MARK: - PRIVATE HELPERS

private extension EnvironmentManager {
    
    func setupBackgroundDecor() {
       guard let scene else { return }
       for i in 0..<2 {
           let backDecor = SKSpriteNode(imageNamed: "back_decor")
           let middleDecor = SKSpriteNode(imageNamed: "middle_decor")
           
           backDecor.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.gameHeightSize)
           backDecor.position = CGPoint(x: scene.size.width / 2 + (CGFloat(i) * GameConstant.gameWidthSize), y: scene.size.height * 0.75)

           backDecor.zPosition = -3
           backDecor.name = "clouds"
           scene.addChild(backDecor)
           
           middleDecor.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.gameHeightSize)
           middleDecor.position = CGPoint(x: scene.size.width / 2 + (CGFloat(i) * GameConstant.gameWidthSize), y: scene.size.height / 2)
           middleDecor.zPosition = -2
           middleDecor.name = "clouds"
           scene.addChild(middleDecor)
       }
   }
    
    func setupRainDecor() {
        guard let scene else { return }
        for i in 0...3 {
            let rain = SKSpriteNode(imageNamed: "rain_0")
            rain.size = CGSize(width: scene.size.width, height: GameConstant.gameHeightSize / 2)
            rain.anchorPoint = CGPoint(x: 0.5, y: 0)
            rain.position = CGPoint(x: scene.size.width / 2, y: GameConstant.gameHeightSize + CGFloat(i) * GameConstant.gameHeightSize / 2)
            rain.zPosition = 5
            rain.name = "rain"
            rain.isHidden = true
            scene.addChild(rain)
        }
    }
    
    func startRainAnimation() {
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            let sky = node as! SKSpriteNode
            let moveAction = SKAction.moveBy(x: 0, y: -100, duration: 1.0)
            let repeatAction = SKAction.repeatForever(moveAction)
            sky.run(repeatAction, withKey: GameConstant.rainAnimation)
        }
    }
    
    func setupMarket() {
        guard let scene else { return }
        marketTextures = loadAtlas(named: "MarketSprite", prefix: "market_")
        // Starts fully off-screen; its left edge enters the view after
        // marketRevealScrollSeconds of scrolling right at scrollSpeedPerSecond
        marketNode.position = CGPoint(
            x: scene.size.width
                + GameConstant.marketSize.width / 2
                + Constant.scrollSpeedPerSecond * Constant.marketRevealScrollSeconds,
            y: GameConstant.floorHeightSize * Constant.marketFloorHeightMultiplier
        )
        marketNode.size = GameConstant.marketSize
        marketNode.zPosition = 1
        marketNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        marketNode.name = ForestConstant.marketName
        idleMarket()
        scene.addChild(marketNode)
    }
    
    func setupAnnouncementSign() {
        guard let scene else { return }
        announcementSignNode.position = CGPoint(
            x: scene.size.width * Constant.announcementSignRelativeX,
            y: GameConstant.floorHeightSize * Constant.announcementSignFloorHeightMultiplier
        )
        announcementSignNode.size = GameConstant.announcementSignSize
        announcementSignNode.zPosition = 1
        announcementSignNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        announcementSignNode.name = "announcementButton"
        scene.addChild(announcementSignNode)
    }

    func idleMarket() {
        guard !marketTextures.isEmpty else { return }
        let animate = SKAction.animate(with: marketTextures, timePerFrame: GameConstant.waitingTimePerFrame * Constant.marketIdleTimeMultiplier)
        marketNode.run(SKAction.repeatForever(animate), withKey: GameConstant.marketAnimation )
    }
    
    func loadAtlas(named atlasName: String, prefix: String) -> [SKTexture] {
        let atlas = SKTextureAtlas(named: atlasName)
        var textures: [SKTexture] = []
        for i in 0..<atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(prefix)\(i)"))
        }
        return textures
    }
    
    func setupFloor() {
        guard let scene else { return }
        floorNode.position = CGPoint(x: scene.size.width / 2, y: 0)
        floorNode.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.floorHeightSize)
        floorNode.zPosition = 1
        floorNode.name = ForestConstant.floorName
        floorNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        scene.addChild(floorNode)
    }
    
    func moveSky(){
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "clouds") { node, _ in
            let sky = node as! SKSpriteNode
            let moveAction = SKAction.moveBy(x: -10, y: 0, duration: 1.0)
            let repeatAction = SKAction.repeatForever(moveAction)
            sky.run(repeatAction, withKey: GameConstant.airAction)
        }
    }
    
    func checkRain() {
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            let rain = node as! SKSpriteNode
            if rain.position.y + rain.bounds.height <= 0 {
                rain.position.y = GameConstant.gameHeightSize
            }
        }
    }

    func isScrollingNode(_ node: SKNode) -> Bool {
        node == floorNode || node == waterStatue || node == grassStatue || node == marketNode ||
        node == announcementSignNode ||
        node.name == "Animal" || node.name == "sculpture" || node.name == "plant"
    }

    func checkInfinitySky() {
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "clouds") { node, _ in
            let sky = node as! SKSpriteNode
            let skyWidth = sky.size.width
            if sky.position.x <= -skyWidth / 2 {
                sky.position.x += skyWidth * 2
            }
            if sky.position.x >= scene.size.width + skyWidth / 2 {
                sky.position.x -= skyWidth * 2
            }
        }
    }
}

extension EnvironmentManager: EnvironmentManagerProtocol {

    func setupEnvironment() {
        setupSky()
        setupBackgroundDecor()
        setupRainDecor()
        setupFloor()
        setupUI()
        moveSky()
        setupMarket()
        setupAnnouncementSign()
    }
    
    // MARK: - SETUP FUNCTIONS
    
    func setupUI() {
        guard let scene else { return }
        scoreLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 80)
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        let menuColumn: [(button: SKSpriteNode, name: String)] = [
            (menuButton, Constant.menuButtonName),
            (announcementButton, "announcementButton"),
            (playButton, "play_button"),
            (forestButton, "forest_button")
        ]
        let buttonSide = max(scene.size.height * ForestConstant.menuButtonRelativeSize, ForestConstant.menuButtonMinSize)
        for (index, entry) in menuColumn.enumerated() {
            entry.button.position = CGPoint(
                x: scene.size.width * ForestConstant.menuButtonRelativeX,
                y: scene.size.height * ForestConstant.menuButtonRelativeYs[index]
            )
            entry.button.zPosition = 4
            entry.button.size = CGSize(width: buttonSide, height: buttonSide)
            entry.button.name = entry.name
        }
        rightIcon.name = ForestConstant.rightIconName
        leftIcon.name = ForestConstant.leftIconName
        downIcon.name = ForestConstant.downIconName
        upIcon.name = ForestConstant.upIconName
        confirmIcon.name = ForestConstant.confirmIconName
        refuseIcon.name = ForestConstant.refuseIconName
        scene.addChild(forestButton)
        scene.addChild(playButton)
        scene.addChild(announcementButton)
        scene.addChild(menuButton)
        scene.addChild(scoreLabel)
    }
    
    func setupSky() {
        guard let scene = scene else { return }
        skyDecor.size = CGSize(width: GameConstant.gameWidthSize, height: GameConstant.gameHeightSize)
        skyDecor.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        skyDecor.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        skyDecor.zPosition = -4
        scene.addChild(skyDecor)
    }
    
    // MARK: - MOVEMENT LOGIC
    
    func moveBackground(direction: HorizontalDirection) {
        guard let scene = scene else { return }

        for node in scene.children where isScrollingNode(node) {
            let moveAction = SKAction.moveBy(
                x: direction == .left ? Constant.scrollSpeedPerSecond : -Constant.scrollSpeedPerSecond,
                y: 0,
                duration: 1.0
            )
            let repeatAction = SKAction.repeatForever(moveAction)

            if node.action(forKey: GameConstant.backgroundAction) == nil {
                node.run(repeatAction, withKey: GameConstant.backgroundAction)
            }
        }
    }

    func stopBackground() {
        guard let scene = scene else { return }
        for node in scene.children {
            node.removeAction(forKey: GameConstant.backgroundAction)
        }
    }
    
    func update() {
        checkInfinitySky()
        if isRaining {
            checkRain()
        }
    }
    
    func startRain() {
        guard let scene else { return }
        isRaining = true
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            let rain = node as! SKSpriteNode
            rain.isHidden = false
        }
        startRainAnimation()
    }
    
    func stopRain() {
        guard let scene else { return }
        isRaining = false
        scene.enumerateChildNodes(withName: "rain") { node, _ in
            node.removeAction(forKey: GameConstant.rainAnimation)
            node.isHidden = true
        }
    }
    
    func startDrought() {
        floorNode.color = .brown
        floorNode.colorBlendFactor = 0.8
    }

    func finishDrought() {
        floorNode.colorBlendFactor = 0.0
    }
    
    // MARK: - POSITION UPDATE
    
    func showPositionArrows() {
        guard let scene else { return }
        if rightIcon.parent != nil || icons.isEmpty {
            return
        }
        rightIcon.position = CGPoint(x: scene.size.width * 0.65, y: scene.size.height * 0.6)
        leftIcon.position = CGPoint(x: scene.size.width * 0.35, y: scene.size.height * 0.6)
        upIcon.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.67)
        downIcon.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.53)
        confirmIcon.position = CGPoint(x: scene.size.width * 0.75, y: scene.size.height * 0.48)
        refuseIcon.position = CGPoint(x: scene.size.width * 0.25, y: scene.size.height * 0.48)
        for icon in icons {
            let iconSize = scene.size.width * 0.15
            icon.size = CGSize(width: iconSize, height: iconSize)
            icon.zPosition = 10.0
            icon.anchorPoint = CGPoint(x: 0.5, y: 0)
            scene.addChild(icon)
        }
    }
    
    func closePositionArrows() {
        for icon in icons {
            icon.removeFromParent()
        }
    }
    
    // MARK: - ANNOUNCEMENT CLAIM INDICATOR
    
    func setAnnouncementClaimable(_ isClaimable: Bool) {
        if isClaimable {
            setupAnnouncementIndicatorsIfNeeded()
        }
        announcementBadgeNode?.isHidden = !isClaimable
    }
    
    private func setupAnnouncementIndicatorsIfNeeded() {
        guard let scene, announcementBadgeNode == nil else { return }
        let buttonSize = max(scene.size.height * ForestConstant.menuButtonRelativeSize, ForestConstant.menuButtonMinSize)
        
        // "!" badge on the top-right corner of the button (kept as a sibling node
        // because changing the sprite's size also scales its children)
        let badgeRadius = buttonSize * 0.2
        let badge = SKShapeNode(circleOfRadius: badgeRadius)
        badge.fillColor = SKColor(red: 0.97, green: 0.94, blue: 0.87, alpha: 1.0)
        badge.strokeColor = SKColor(red: 0.45, green: 0.31, blue: 0.18, alpha: 1.0)
        badge.lineWidth = badgeRadius * 0.22
        badge.position = CGPoint(
            x: announcementButton.position.x + buttonSize * 0.4,
            y: announcementButton.position.y + buttonSize * 0.4
        )
        badge.zPosition = announcementButton.zPosition + 0.1
        badge.name = "announcementButton"
        
        let exclamation = SKLabelNode(fontNamed: "AvenirNext-Bold")
        exclamation.text = "!"
        exclamation.fontSize = badgeRadius * 1.6
        exclamation.fontColor = SKColor(red: 0.45, green: 0.31, blue: 0.18, alpha: 1.0)
        exclamation.verticalAlignmentMode = .center
        exclamation.horizontalAlignmentMode = .center
        exclamation.name = "announcementButton"
        badge.addChild(exclamation)
        
        scene.addChild(badge)
        announcementBadgeNode = badge
    }
}
