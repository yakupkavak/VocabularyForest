//
//  ForestTourManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.08.2026.
//

import SpriteKit

protocol ForestTourManagerProtocol: AnyObject {
    var isActive: Bool { get }
    var onWalkHintChanged: ((HorizontalDirection?) -> Void)? { get set }
    var onFinished: (() -> Void)? { get set }
    func start()
    func update()
    func handleTouch(nodes: [SKNode]) -> Bool
}

/// Ordered stops of the first-launch guided tour. Talk steps advance on tap;
/// follow steps advance once the target structure scrolls fully into view,
/// which proves the user actually walked there.
private enum ForestTourStep {
    case inactive
    case entering
    case welcome
    case board
    case followGate
    case gate
    case followMarket
    case market
    case ready
    case finished
}

// MARK: - CONSTANTS

private extension ForestTourManager {
    enum Constants {
        static let rabbitAssetType = "Rabbit"
        static let rabbitNodeName = "tourRabbit"
        static let idleAtlasSuffix = "Idle"
        static let walkAtlasSuffix = "Walk"
        static let jumpAtlasSuffix = "Jump"
        static let idleFrameInfix = "_idle_"
        static let walkFrameInfix = "_walk_"
        static let jumpFrameInfix = "_jump_"

        static let anchorPointX: CGFloat = 0.5
        static let anchorPointY: CGFloat = 0.0
        static let floorHeightMultiplier: CGFloat = 0.65
        static let zPosition: CGFloat = 3.0
        static let halfDivider: CGFloat = 2.0
        static let scaleLeft: CGFloat = -1.0
        static let scaleRight: CGFloat = 1.0
        static let defaultAspectRatio: CGFloat = 1.0
        static let zero: CGFloat = 0.0

        static let idleTimeMultiplier: Double = 2.0
        /// Per-frame chase speed; at 60fps this outruns scrollSpeedPerSecond so
        /// the rabbit keeps its lead while the world scrolls under it.
        static let walkSpeedPerFrame: CGFloat = 4.0
        static let arrivalThreshold: CGFloat = 8.0
        static let spawnOffscreenOffset: CGFloat = 60.0
        static let anchorGap: CGFloat = 12.0
        static let finishFadeDuration: TimeInterval = 0.5
    }
}

final class ForestTourManager {

    // MARK: - PROPERTIES

    private weak var scene: SKScene?
    private let rabbitNode = SKSpriteNode()
    private var idleTextures: [SKTexture] = []
    private var walkTextures: [SKTexture] = []
    private var jumpTextures: [SKTexture] = []
    private var step: ForestTourStep = .inactive
    private var isWalking = false
    var onWalkHintChanged: ((HorizontalDirection?) -> Void)?
    var onFinished: (() -> Void)?

    // MARK: - INIT

    init(scene: SKScene) {
        self.scene = scene
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension ForestTourManager: ForestTourManagerProtocol {

    var isActive: Bool {
        step != .inactive && step != .finished
    }

    func start() {
        guard let scene else { return }
        loadTextures()
        // Missing atlases must not trap the user in an unfinishable tour.
        guard !idleTextures.isEmpty, !walkTextures.isEmpty else {
            step = .finished
            onFinished?()
            return
        }
        setupRabbit(in: scene)
        step = .entering
    }

    func update() {
        guard isActive else { return }
        moveTowardAnchor()
        checkFollowProgress()
    }

    func handleTouch(nodes: [SKNode]) -> Bool {
        switch step {
        case .welcome:
            advance(to: .board)
            return true
        case .board:
            advance(to: .followGate)
            return true
        case .gate:
            advance(to: .followMarket)
            return true
        case .market:
            advance(to: .ready)
            return true
        case .ready:
            if nodes.contains(where: { $0.name == ForestConstant.tourAcceptButtonName }) {
                advance(to: .finished)
            }
            return true
        case .followGate, .followMarket:
            // Walking is the lesson here; let the touch fall through to the player.
            return false
        case .inactive, .entering, .finished:
            return true
        }
    }
}

// MARK: - HELPERS

private extension ForestTourManager {

    // MARK: - SETUP

    func loadTextures() {
        let type = Constants.rabbitAssetType
        idleTextures = loadAtlas(named: type + Constants.idleAtlasSuffix, prefix: type.lowercased() + Constants.idleFrameInfix)
        walkTextures = loadAtlas(named: type + Constants.walkAtlasSuffix, prefix: type.lowercased() + Constants.walkFrameInfix)
        jumpTextures = loadAtlas(named: type + Constants.jumpAtlasSuffix, prefix: type.lowercased() + Constants.jumpFrameInfix)
    }

    func loadAtlas(named atlasName: String, prefix: String) -> [SKTexture] {
        let atlas = SKTextureAtlas(named: atlasName)
        var textures: [SKTexture] = []
        for i in 0..<atlas.textureNames.count {
            textures.append(atlas.textureNamed("\(prefix)\(i)"))
        }
        return textures
    }

    func setupRabbit(in scene: SKScene) {
        guard let firstFrame = idleTextures.first else { return }
        rabbitNode.texture = firstFrame
        let originalSize = firstFrame.size()
        let aspectRatio = originalSize.height > Constants.zero
            ? originalSize.width / originalSize.height
            : Constants.defaultAspectRatio
        rabbitNode.size = CGSize(
            width: ComponentSizeConstant.animalHeight * aspectRatio,
            height: ComponentSizeConstant.animalHeight
        )
        rabbitNode.anchorPoint = CGPoint(x: Constants.anchorPointX, y: Constants.anchorPointY)
        rabbitNode.position = CGPoint(
            x: -rabbitNode.size.width - Constants.spawnOffscreenOffset,
            y: GameConstant.floorHeightSize * Constants.floorHeightMultiplier
        )
        rabbitNode.zPosition = Constants.zPosition
        rabbitNode.name = Constants.rabbitNodeName
        startIdleAnimation()
        scene.addChild(rabbitNode)
    }

    // MARK: - MOVEMENT

    /// Scene-space X the rabbit keeps chasing. Anchors are read from the live
    /// structure nodes each frame, so the rabbit stays glued to its stop even
    /// while the whole world scrolls under the player's feet.
    var anchorX: CGFloat? {
        guard let scene else { return nil }
        switch step {
        case .entering, .welcome, .board:
            guard let board = scene.childNode(withName: ForestConstant.announcementButtonName) as? SKSpriteNode else { return nil }
            return board.position.x + board.size.width / Constants.halfDivider + rabbitHalfWidth + Constants.anchorGap
        case .followGate, .gate:
            guard let gate = scene.childNode(withName: ForestConstant.adventureGateName) as? SKSpriteNode else { return nil }
            return gate.position.x + gate.size.width / Constants.halfDivider + rabbitHalfWidth + Constants.anchorGap
        case .followMarket, .market, .ready:
            guard let market = scene.childNode(withName: ForestConstant.marketName) as? SKSpriteNode else { return nil }
            return market.position.x - market.size.width / Constants.halfDivider - rabbitHalfWidth - Constants.anchorGap
        case .inactive, .finished:
            return nil
        }
    }

    var rabbitHalfWidth: CGFloat {
        rabbitNode.size.width / Constants.halfDivider
    }

    func moveTowardAnchor() {
        guard let anchorX else { return }
        let dx = anchorX - rabbitNode.position.x
        if abs(dx) > Constants.arrivalThreshold {
            face(direction: dx < Constants.zero ? .left : .right)
            startWalkAnimationIfNeeded()
            let stepX = max(-Constants.walkSpeedPerFrame, min(Constants.walkSpeedPerFrame, dx))
            rabbitNode.position.x += stepX
            isWalking = true
        } else if isWalking {
            isWalking = false
            stopWalkAnimation()
            faceScreenCenter()
            if step == .entering {
                advance(to: .welcome)
            }
        }
    }

    func checkFollowProgress() {
        guard let scene else { return }
        switch step {
        case .followGate:
            if let gate = scene.childNode(withName: ForestConstant.adventureGateName) as? SKSpriteNode,
               gate.position.x >= gate.size.width / Constants.halfDivider {
                advance(to: .gate)
            }
        case .followMarket:
            if let market = scene.childNode(withName: ForestConstant.marketName) as? SKSpriteNode,
               market.position.x <= scene.size.width - market.size.width / Constants.halfDivider {
                advance(to: .market)
            }
        default:
            break
        }
    }

    // MARK: - STEP MACHINE

    func advance(to newStep: ForestTourStep) {
        step = newStep
        removeBubble()
        switch newStep {
        case .welcome:
            talk(String(localized: "tour_welcome"))
        case .board:
            talk(String(localized: "tour_board_intro"))
        case .followGate:
            talk(String(localized: "tour_follow_gate"))
            onWalkHintChanged?(.left)
        case .gate:
            onWalkHintChanged?(nil)
            talk(String(localized: "tour_gate_intro"))
        case .followMarket:
            talk(String(localized: "tour_follow_market"))
            onWalkHintChanged?(.right)
        case .market:
            onWalkHintChanged?(nil)
            talk(String(localized: "tour_market_intro"))
        case .ready:
            askReadyQuestion()
        case .finished:
            finishTour()
        case .inactive, .entering:
            break
        }
    }

    // MARK: - TALK

    func talk(_ text: String) {
        let bubble = ComponentBubble.createTalkBubble(
            parentSize: rabbitNode.size,
            parentXScale: rabbitNode.xScale,
            text: text,
            width: ComponentBubble.Constants.tourBubbleWidth,
            autoClose: false
        )
        rabbitNode.addChild(bubble)
        A11yAnnouncer.announce(text)
    }

    func askReadyQuestion() {
        let text = String(localized: "tour_ready_question")
        let bubble = ComponentBubble.createTourQuestionBubble(
            parentSize: rabbitNode.size,
            parentXScale: rabbitNode.xScale,
            text: text
        )
        rabbitNode.addChild(bubble)
        A11yAnnouncer.announce(text)
    }

    func removeBubble() {
        rabbitNode.childNode(withName: ComponentBubble.Constants.talkBubbleName)?.removeFromParent()
    }

    // MARK: - ANIMATIONS

    func face(direction: HorizontalDirection) {
        let newScale: CGFloat = direction == .left ? Constants.scaleLeft : Constants.scaleRight
        guard rabbitNode.xScale != newScale else { return }
        rabbitNode.xScale = newScale
        // Counter-flip any attached bubble so its text keeps reading left-to-right.
        rabbitNode.childNode(withName: ComponentBubble.Constants.talkBubbleName)?.xScale = newScale
    }

    func faceScreenCenter() {
        guard let scene else { return }
        let centerX = scene.size.width / Constants.halfDivider
        face(direction: rabbitNode.position.x > centerX ? .left : .right)
    }

    func startIdleAnimation() {
        guard !idleTextures.isEmpty else { return }
        rabbitNode.removeAction(forKey: GameConstant.movingCharacterAnimation)
        if rabbitNode.action(forKey: GameConstant.waitingCharacterAnimation) == nil {
            let animate = SKAction.animate(with: idleTextures, timePerFrame: GameConstant.waitingTimePerFrame * Constants.idleTimeMultiplier)
            rabbitNode.run(SKAction.repeatForever(animate), withKey: GameConstant.waitingCharacterAnimation)
        }
    }

    func startWalkAnimationIfNeeded() {
        guard !walkTextures.isEmpty, rabbitNode.action(forKey: GameConstant.movingCharacterAnimation) == nil else { return }
        rabbitNode.removeAction(forKey: GameConstant.waitingCharacterAnimation)
        let animate = SKAction.animate(with: walkTextures, timePerFrame: GameConstant.movingTimePerFrame)
        rabbitNode.run(SKAction.repeatForever(animate), withKey: GameConstant.movingCharacterAnimation)
    }

    func stopWalkAnimation() {
        rabbitNode.removeAction(forKey: GameConstant.movingCharacterAnimation)
        startIdleAnimation()
    }

    // MARK: - FINISH

    func finishTour() {
        onWalkHintChanged?(nil)
        rabbitNode.removeAction(forKey: GameConstant.waitingCharacterAnimation)
        let jump = SKAction.animate(with: jumpTextures, timePerFrame: GameConstant.jumpTimePerFrame)
        let fade = SKAction.fadeOut(withDuration: Constants.finishFadeDuration)
        let notify = SKAction.run { [weak self] in
            self?.onFinished?()
        }
        rabbitNode.run(.sequence([jump, fade, notify, .removeFromParent()]))
    }
}
