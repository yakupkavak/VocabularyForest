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
        /// The guide should read larger than regular forest animals.
        static let sizeMultiplier: CGFloat = 1.3
        /// Calm stroll speed (60pt/s at 60fps) relative to the scrolling
        /// world; the world scroll moves the rabbit like any planted animal,
        /// so the player's walking no longer distorts the rabbit's pace.
        static let walkSpeedPerFrame: CGFloat = 1.0
        /// Ease-out zone before a stop; speed scales down linearly inside it
        /// so arrival reads as a landing instead of an abrupt halt.
        static let arrivalEaseDistance: CGFloat = 60.0
        static let minWalkSpeedPerFrame: CGFloat = 0.4
        /// Catch-up clamp for residual offset while standing (e.g. from the
        /// beat before the scroll action attached to the rabbit).
        static let idleDriftSpeedPerFrame: CGFloat = 2.4
        /// Hysteresis pair keeping small anchor jitter from flip-flopping the
        /// rabbit between walk and idle animations.
        static let startWalkingDistance: CGFloat = 24.0
        static let stopWalkingDistance: CGFloat = 4.0
        static let anchorGap: CGFloat = 12.0
        /// Pushes the first stop toward screen center so the rabbit doesn't
        /// spawn hugging the board at the screen edge.
        static let welcomeAnchorScreenFraction: CGFloat = 0.10
        /// Lowers the tour bubble by this fraction of the rabbit's height so
        /// it hovers beside the head instead of floating high above it.
        static let bubbleLowerHeightFraction: CGFloat = 0.45
        static let finishFadeDuration: TimeInterval = 0.5
        /// How long the farewell thank-you bubble stays up before the rabbit
        /// jumps away.
        static let thanksHoldDuration: TimeInterval = 1.5
        /// A follow step completes once the target structure is fully on
        /// screen plus this fraction of the screen width further in, so the
        /// arrival registers just past the moment the structure is revealed.
        static let followArrivalScreenFraction: CGFloat = 0.02

        /// Ready-step confirm control: a lone tick at the bottom center of
        /// the screen instead of a button crammed inside the speech bubble.
        static let acceptButtonImageName = "accept_button"
        static let readyButtonSize: CGFloat = 56.0
        static let readyButtonBottomOffset: CGFloat = 90.0

        /// Bottom-center Next arrow that pages the tour dialogue; it only
        /// appears when the player is at the right spot, hiding entirely
        /// while a follow step waits on the player walking.
        static let nextButtonImageName = "next_button"
        static let nextButtonSize: CGFloat = 64.0
        /// One-second dip after every tap: the arrow fades away and returns,
        /// pacing taps so each new sentence gets read before the next one.
        static let nextButtonCooldownActionKey = "tourNextCooldown"
        static let nextButtonCooldownFade: TimeInterval = 0.2
        static let nextButtonCooldownHold: TimeInterval = 0.6
        static let fullAlpha: CGFloat = 1.0

        /// Spotlight layering: the dim veil sits above every world node, and
        /// the featured structure, rabbit, and player are raised above it.
        static let dimNodeName = "tourDim"
        static let dimAlpha: CGFloat = 0.4
        static let dimZPosition: CGFloat = 50.0
        static let spotlitZPosition: CGFloat = 51.0
    }
}

final class ForestTourManager {

    // MARK: - PROPERTIES

    private weak var scene: SKScene?
    private weak var playerNode: SKSpriteNode?
    private let rabbitNode = SKSpriteNode()
    private let dimNode = SKSpriteNode()
    private let nextButtonNode = SKSpriteNode()
    private var idleTextures: [SKTexture] = []
    private var walkTextures: [SKTexture] = []
    private var jumpTextures: [SKTexture] = []
    private var step: ForestTourStep = .inactive
    private var isWalking = false
    private var pendingSentences: [String] = []
    private var spotlitNode: SKNode?
    private var spotlitNodeOriginalZ: CGFloat = Constants.zero
    private var playerOriginalZ: CGFloat = Constants.zero
    var onWalkHintChanged: ((HorizontalDirection?) -> Void)?
    var onFinished: (() -> Void)?

    // MARK: - INIT

    init(scene: SKScene, playerNode: SKSpriteNode) {
        self.scene = scene
        self.playerNode = playerNode
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
        setupDim(in: scene)
        setupNextButton(in: scene)
        // The guide is already waiting at its first stop when the forest
        // appears; walking in from off-screen read as a glitch, not an entrance.
        step = .entering
        if let anchorX {
            rabbitNode.position.x = anchorX
        }
        faceScreenCenter()
        advance(to: .welcome)
    }

    func update() {
        guard isActive else { return }
        moveTowardAnchor()
        checkFollowProgress()
        // Single source of truth for the arrow: talking, standing still, and
        // with something left to advance — otherwise it stays hidden.
        nextButtonNode.isHidden = !shouldShowNextButton
    }

    func handleTouch(nodes: [SKNode]) -> Bool {
        switch step {
        case .welcome:
            if isNextButtonTapped(nodes) {
                advanceSentenceOrStep(to: .board)
                pulseNextButton()
            }
            return true
        case .board:
            if isNextButtonTapped(nodes) {
                advanceSentenceOrStep(to: .followGate)
                pulseNextButton()
            }
            return true
        case .gate:
            if isNextButtonTapped(nodes) {
                advanceSentenceOrStep(to: .followMarket)
                pulseNextButton()
            }
            return true
        case .market:
            if isNextButtonTapped(nodes) {
                advanceSentenceOrStep(to: .ready)
                pulseNextButton()
            }
            return true
        case .ready:
            if nodes.contains(where: { $0.name == ForestConstant.tourAcceptButtonName }) {
                advance(to: .finished)
            }
            return true
        case .followGate, .followMarket:
            // Next pages the remaining hint sentences, then goes inert while
            // walking is the lesson; all other touches drive the player.
            if isNextButtonTapped(nodes), !pendingSentences.isEmpty {
                showNextSentence()
                pulseNextButton()
                return true
            }
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
        let rabbitHeight = ComponentSizeConstant.animalHeight * Constants.sizeMultiplier
        rabbitNode.size = CGSize(
            width: rabbitHeight * aspectRatio,
            height: rabbitHeight
        )
        rabbitNode.anchorPoint = CGPoint(x: Constants.anchorPointX, y: Constants.anchorPointY)
        // Fallback position only; start() moves the rabbit to its first anchor.
        rabbitNode.position = CGPoint(
            x: scene.size.width / Constants.halfDivider,
            y: GameConstant.floorHeightSize * Constants.floorHeightMultiplier
        )
        rabbitNode.zPosition = Constants.zPosition
        rabbitNode.name = ForestConstant.tourRabbitName
        startIdleAnimation()
        scene.addChild(rabbitNode)
    }

    func setupNextButton(in scene: SKScene) {
        nextButtonNode.texture = SKTexture(imageNamed: Constants.nextButtonImageName)
        nextButtonNode.size = CGSize(width: Constants.nextButtonSize, height: Constants.nextButtonSize)
        nextButtonNode.name = ForestConstant.tourNextButtonName
        nextButtonNode.zPosition = Constants.spotlitZPosition
        nextButtonNode.position = CGPoint(
            x: scene.size.width / Constants.halfDivider,
            y: Constants.readyButtonBottomOffset
        )
        nextButtonNode.isHidden = true
        scene.addChild(nextButtonNode)
    }

    var shouldShowNextButton: Bool {
        switch step {
        case .welcome, .board, .gate, .market:
            // The spotlight veil is up on these steps: the arrow must be
            // available even while the rabbit is still settling into place.
            return true
        case .followGate, .followMarket:
            return isRabbitTalking && !isWalking && !pendingSentences.isEmpty
        case .inactive, .entering, .ready, .finished:
            return false
        }
    }

    func isNextButtonTapped(_ nodes: [SKNode]) -> Bool {
        // Ignore taps while the post-tap dip animation is still running.
        guard nextButtonNode.action(forKey: Constants.nextButtonCooldownActionKey) == nil else { return false }
        return nodes.contains { $0.name == ForestConstant.tourNextButtonName }
    }

    func pulseNextButton() {
        guard !nextButtonNode.isHidden else { return }
        let fadeOut = SKAction.fadeOut(withDuration: Constants.nextButtonCooldownFade)
        let hold = SKAction.wait(forDuration: Constants.nextButtonCooldownHold)
        let fadeIn = SKAction.fadeIn(withDuration: Constants.nextButtonCooldownFade)
        nextButtonNode.run(
            .sequence([fadeOut, hold, fadeIn]),
            withKey: Constants.nextButtonCooldownActionKey
        )
    }

    func setupDim(in scene: SKScene) {
        dimNode.color = .black
        dimNode.alpha = Constants.dimAlpha
        dimNode.size = scene.size
        dimNode.anchorPoint = CGPoint(x: Constants.zero, y: Constants.zero)
        dimNode.position = CGPoint(x: Constants.zero, y: Constants.zero)
        dimNode.zPosition = Constants.dimZPosition
        dimNode.name = Constants.dimNodeName
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
                + scene.size.width * Constants.welcomeAnchorScreenFraction
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
        if !isWalking && abs(dx) > Constants.startWalkingDistance {
            isWalking = true
            startWalkAnimationIfNeeded()
        }
        if isWalking {
            face(direction: dx < Constants.zero ? .left : .right)
            // Linear ease-out: full stride far away, decelerating inside the
            // arrival zone so the stop reads as a landing, not a teleport.
            let easedSpeed = min(
                Constants.walkSpeedPerFrame,
                max(Constants.minWalkSpeedPerFrame,
                    Constants.walkSpeedPerFrame * abs(dx) / Constants.arrivalEaseDistance)
            )
            rabbitNode.position.x += dx < Constants.zero ? -easedSpeed : easedSpeed
            if abs(dx) <= Constants.stopWalkingDistance {
                isWalking = false
                stopWalkAnimation()
                faceScreenCenter()
            }
        } else {
            // Standing on scrolling ground: chase the drifting anchor with a
            // clamped step so the rabbit stays planted at its stop without
            // ever jumping there in a single frame.
            let driftX = max(-Constants.idleDriftSpeedPerFrame, min(Constants.idleDriftSpeedPerFrame, dx))
            rabbitNode.position.x += driftX
        }
    }

    func checkFollowProgress() {
        guard let scene else { return }
        let arrivalMargin = scene.size.width * Constants.followArrivalScreenFraction
        switch step {
        case .followGate:
            if let gate = scene.childNode(withName: ForestConstant.adventureGateName) as? SKSpriteNode,
               gate.position.x >= gate.size.width / Constants.halfDivider + arrivalMargin {
                advance(to: .gate)
            }
        case .followMarket:
            if let market = scene.childNode(withName: ForestConstant.marketName) as? SKSpriteNode,
               market.position.x <= scene.size.width - market.size.width / Constants.halfDivider - arrivalMargin {
                advance(to: .market)
            }
        default:
            break
        }
    }

    // MARK: - STEP MACHINE

    /// Shows the next queued sentence if the current step is still mid-speech,
    /// otherwise moves the tour forward. Keeps taps advancing one sentence at
    /// a time instead of dumping the whole paragraph at once.
    func advanceSentenceOrStep(to nextStep: ForestTourStep) {
        if pendingSentences.isEmpty {
            advance(to: nextStep)
        } else {
            showNextSentence()
        }
    }

    func advance(to newStep: ForestTourStep) {
        step = newStep
        pendingSentences.removeAll()
        removeBubble()
        switch newStep {
        case .welcome:
            showSpotlight(on: nil)
            talk(String(localized: "tour_welcome"))
        case .board:
            showSpotlight(on: ForestConstant.announcementButtonName)
            talk(String(localized: "tour_board_intro"))
        case .followGate:
            hideSpotlight()
            talk(String(localized: "tour_follow_gate"))
            onWalkHintChanged?(.left)
        case .gate:
            onWalkHintChanged?(nil)
            showSpotlight(on: ForestConstant.adventureGateName)
            talk(String(localized: "tour_gate_intro"))
        case .followMarket:
            hideSpotlight()
            talk(String(localized: "tour_follow_market"))
            // Walking was already taught on the gate leg; once the user has
            // reached the adventure gate the hint never shows again.
            onWalkHintChanged?(nil)
        case .market:
            onWalkHintChanged?(nil)
            showSpotlight(on: ForestConstant.marketName)
            talk(String(localized: "tour_market_intro"))
        case .ready:
            showSpotlight(on: nil)
            askReadyQuestion()
        case .finished:
            hideSpotlight()
            finishTour()
        case .inactive, .entering:
            break
        }
    }

    // MARK: - SPOTLIGHT

    /// Dims the whole forest and lifts the featured structure, the rabbit,
    /// and the player above the veil so only the lesson's actors stay bright.
    func showSpotlight(on nodeName: String?) {
        guard let scene else { return }
        restoreSpotlitNode()
        if dimNode.parent == nil {
            scene.addChild(dimNode)
            if let playerNode {
                playerOriginalZ = playerNode.zPosition
                playerNode.zPosition = Constants.spotlitZPosition
            }
            rabbitNode.zPosition = Constants.spotlitZPosition
        }
        if let nodeName, let node = scene.childNode(withName: nodeName) {
            spotlitNode = node
            spotlitNodeOriginalZ = node.zPosition
            node.zPosition = Constants.spotlitZPosition
        }
    }

    func hideSpotlight() {
        restoreSpotlitNode()
        guard dimNode.parent != nil else { return }
        dimNode.removeFromParent()
        playerNode?.zPosition = playerOriginalZ
        rabbitNode.zPosition = Constants.zPosition
    }

    func restoreSpotlitNode() {
        spotlitNode?.zPosition = spotlitNodeOriginalZ
        spotlitNode = nil
    }

    // MARK: - TALK

    func talk(_ text: String) {
        pendingSentences = splitSentences(of: text)
        showNextSentence()
    }

    func showNextSentence() {
        removeBubble()
        guard !pendingSentences.isEmpty else { return }
        let sentence = pendingSentences.removeFirst()
        let bubble = ComponentBubble.createTalkBubble(
            parentSize: rabbitNode.size,
            parentXScale: rabbitNode.xScale,
            text: sentence,
            width: ComponentBubble.Constants.tourBubbleWidth,
            minHeight: ComponentBubble.Constants.tourBubbleMinHeight,
            gap: ComponentBubble.Constants.tourBubbleGap
                - rabbitNode.size.height * Constants.bubbleLowerHeightFraction,
            autoClose: false
        )
        rabbitNode.addChild(bubble)
        A11yAnnouncer.announce(sentence)
    }

    /// Locale-aware sentence split so every supported language's tour reads
    /// one line at a time; falls back to the whole text when no boundary exists.
    func splitSentences(of text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: [.bySentences, .localized]) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty {
                sentences.append(sentence)
            }
        }
        return sentences.isEmpty ? [text] : sentences
    }

    func askReadyQuestion() {
        talk(String(localized: "tour_ready_question"))
        addReadyButton()
    }

    func addReadyButton() {
        guard let scene else { return }
        let button = SKSpriteNode(imageNamed: Constants.acceptButtonImageName)
        button.name = ForestConstant.tourAcceptButtonName
        button.size = CGSize(width: Constants.readyButtonSize, height: Constants.readyButtonSize)
        button.position = CGPoint(
            x: scene.size.width / Constants.halfDivider,
            y: Constants.readyButtonBottomOffset
        )
        // Above the spotlight veil so the confirm control stays bright.
        button.zPosition = Constants.spotlitZPosition
        scene.addChild(button)
    }

    func removeReadyButton() {
        scene?.childNode(withName: ForestConstant.tourAcceptButtonName)?.removeFromParent()
    }

    func removeBubble() {
        rabbitNode.childNode(withName: ComponentBubble.Constants.talkBubbleName)?.removeFromParent()
    }

    var isRabbitTalking: Bool {
        rabbitNode.childNode(withName: ComponentBubble.Constants.talkBubbleName) != nil
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
        removeReadyButton()
        nextButtonNode.removeFromParent()
        // Farewell: thank the player, hold the bubble a beat, then jump away.
        talk(String(localized: "tour_thanks"))
        let hold = SKAction.wait(forDuration: Constants.thanksHoldDuration)
        let stopIdle = SKAction.run { [weak self] in
            self?.rabbitNode.removeAction(forKey: GameConstant.waitingCharacterAnimation)
        }
        let jump = SKAction.animate(with: jumpTextures, timePerFrame: GameConstant.jumpTimePerFrame)
        let fade = SKAction.fadeOut(withDuration: Constants.finishFadeDuration)
        let notify = SKAction.run { [weak self] in
            self?.onFinished?()
        }
        rabbitNode.run(.sequence([hold, stopIdle, jump, fade, notify, .removeFromParent()]))
    }
}
