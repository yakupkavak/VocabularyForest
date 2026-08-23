//
//  ComponentBubble.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.03.2026.
//

import SpriteKit

struct ComponentBubble {
    
    // MARK: - CONSTANTS
    
    enum Constants {
        static let zero: CGFloat = 0.0
        
        static let defaultBubbleWidth: CGFloat = 120
        static let defaultBubbleHeight: CGFloat = 80
        
        static let interactionBubbleWidth: CGFloat = 160
        static let interactionBubbleHeight: CGFloat = 120
        
        static let talkBubbleWidth: CGFloat = 180
        static let talkLabelPadding: CGFloat = 25
        static let talkVerticalPadding: CGFloat = 20
        static let talkFontSize: CGFloat = 12
        
        static let talkDotCount: Int = 3
        static let talkDotInitialSize: CGFloat = 15.0
        static let talkDotSizeDecrement: CGFloat = 5.0
        static let talkDotInitialYOffset: CGFloat = 12.0
        static let talkDotVerticalSpacing: CGFloat = 4.0
        static let talkDotXShiftMultiplier: CGFloat = 8.0
        static let talkDotLineWidth: CGFloat = 2.0
        static let talkDotZPosition: CGFloat = -1.0
        static let talkDotsTotalHeight: CGFloat = 38.0
        
        static let defaultCornerRadius: CGFloat = 10
        static let defaultAlpha: CGFloat = 0.95
        static let defaultLineWidth: CGFloat = 2
        static let talkLineWidth: CGFloat = 3
        static let defaultZPosition: CGFloat = 100
        static let defaultYOffset: CGFloat = 40
        
        static let titleFontSize: CGFloat = 16
        static let titleYOffset: CGFloat = 15
        static let interactionTitleYOffset: CGFloat = 25
        static let titleMaxWidthPadding: CGFloat = 24
        
        static let separatorWidthReduction: CGFloat = 20
        static let separatorHeight: CGFloat = 1
        static let separatorAlpha: CGFloat = 0.3
        static let separatorYOffset: CGFloat = 5
        static let verticalSeparatorWidth: CGFloat = 1
        static let verticalSeparatorHeight: CGFloat = 25
        static let verticalSeparatorYOffset: CGFloat = -15
        
        static let buttonWidth: CGFloat = 100
        static let buttonHeight: CGFloat = 30
        static let buttonCornerRadius: CGFloat = 5
        static let buttonAlpha: CGFloat = 0.01
        static let buttonYOffset: CGFloat = -15
        static let buttonZPosition: CGFloat = 5
        static let buttonLabelFontSize: CGFloat = 14
        static let buttonLabelZPosition: CGFloat = 1
        static let defaultButtonMaxWidth: CGFloat = 60
        static let buttonPosXOffset: CGFloat = 32
        static let buttonNegXOffset: CGFloat = -32
        
        static let marketBubbleWidth: CGFloat = 120
        static let marketBubbleHeight: CGFloat = 100
        static let marketIconSize: CGFloat = 60
        /// The balloon texture's tail eats the bottom area; keep the icon above it.
        static let marketIconYOffset: CGFloat = 10
        /// Negative so the balloon's tail overlaps the stall's awning instead of floating above it.
        static let marketBubbleGap: CGFloat = -20

        static let hitboxWidth: CGFloat = 70
        static let hitboxHeight: CGFloat = 50
        static let hitboxYOffset: CGFloat = -20
        static let hitboxNameXOffset: CGFloat = -35
        static let hitboxMoveXOffset: CGFloat = 35
        
        static let animalHitboxWidth: CGFloat = 140
        static let animalHitboxHeight: CGFloat = 50
        static let animalHitboxYOffset: CGFloat = -20
        
        static let talkBubbleName = "talk_bubble"
        static let talkLabelYOffset: CGFloat = 5.0
        static let talkBubbleGap: CGFloat = 2.0
        static let talkBubbleMinHeight: CGFloat = 60.0

        /// Narrower than talkBubbleWidth: the tour rabbit stops beside screen-edge
        /// structures, where a full-width bubble would clip at the display edge.
        static let tourBubbleWidth: CGFloat = 150.0
        /// Half the regular talk minimum: tour sentences are short one-liners.
        static let tourBubbleMinHeight: CGFloat = 30.0
        /// Negative so the tour bubble hugs the rabbit's head instead of
        /// floating a full body-height above it.
        static let tourBubbleGap: CGFloat = -20.0

        static let initialScale: CGFloat = 0.0
        static let scaleDuration: TimeInterval = 0.2
        static let waitDuration: TimeInterval = 3.0
        static let talkWaitDuration: TimeInterval = 6.0
        static let fadeOutDuration: TimeInterval = 0.5
        static let targetScale: CGFloat = 1.0
        static let removeScaleTarget: CGFloat = 0.0
        static let removeDuration: TimeInterval = 0.1
        static let flippedScaleX: CGFloat = -1.0
        static let halfDivider: CGFloat = 2.0
    }
    
    // MARK: - SHARED COMPONENTS
    
    static func createBaseBubble(width: CGFloat, height: CGFloat, parentSize: CGSize, strokeColor: UIColor = .black, lineWidth: CGFloat = Constants.defaultLineWidth) -> SKShapeNode {
        let bubble = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: Constants.defaultCornerRadius)
        bubble.fillColor = .brown500.withAlphaComponent(Constants.defaultAlpha)
        bubble.strokeColor = strokeColor
        bubble.lineWidth = lineWidth
        bubble.zPosition = Constants.defaultZPosition
        bubble.position = CGPoint(x: Constants.zero, y: parentSize.height + Constants.defaultYOffset)
        return bubble
    }
    
    static func createTitleLabel(
        text: String,
        fontColor: UIColor = .white,
        yOffset: CGFloat = Constants.titleYOffset,
        maxWidth: CGFloat? = nil
    ) -> SKLabelNode {
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.fontSize = Constants.titleFontSize
        titleLabel.fontColor = fontColor
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        if let maxWidth {
            titleLabel.numberOfLines = Int(Constants.zero)
            titleLabel.preferredMaxLayoutWidth = maxWidth
            titleLabel.lineBreakMode = .byWordWrapping
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            let titleFont = UIFont(name: "Arial-BoldMT", size: Constants.titleFontSize) ?? .boldSystemFont(ofSize: Constants.titleFontSize)
            titleLabel.attributedText = NSAttributedString(
                string: text,
                attributes: [
                    .paragraphStyle: paragraphStyle,
                    .font: titleFont,
                    .foregroundColor: fontColor
                ]
            )
        } else {
            titleLabel.text = text
        }
        titleLabel.position = CGPoint(x: Constants.zero, y: yOffset)
        return titleLabel
    }
    
    static func createButtonLabel(text: String, name: String, maxWidth: CGFloat? = nil) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = text
        label.fontSize = Constants.buttonLabelFontSize
        label.fontColor = .black
        label.name = name
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        if let width = maxWidth {
            label.numberOfLines = Int(Constants.zero)
            label.preferredMaxLayoutWidth = width
            label.lineBreakMode = .byWordWrapping
        }
        return label
    }
    
    static func createInvisibleHitbox(name: String, width: CGFloat, height: CGFloat, position: CGPoint) -> SKShapeNode {
        let hitbox = SKShapeNode(rectOf: CGSize(width: width, height: height))
        hitbox.name = name
        hitbox.position = position
        hitbox.fillColor = .clear
        hitbox.strokeColor = .clear
        hitbox.zPosition = Constants.buttonZPosition
        return hitbox
    }
    
    // MARK: - SPECIFIC BUBBLES
    
    static func createAnimalMenuBubble(parentSize: CGSize, displayName: String?) -> SKNode {
        let texture = SKTexture(imageNamed: "animal_tap_ballon")
        let bubble = SKSpriteNode(texture: texture)
        bubble.name = "menu_bubble"
        bubble.size = CGSize(width: Constants.interactionBubbleWidth, height: Constants.interactionBubbleHeight)
        bubble.zPosition = Constants.defaultZPosition
        bubble.position = CGPoint(x: Constants.zero, y: parentSize.height + (Constants.interactionBubbleHeight / 2) + 10)
        
        let titleLabel = createTitleLabel(
            text: displayName ?? String(localized: "Animal"),
            fontColor: .darkGray,
            yOffset: Constants.interactionTitleYOffset,
            maxWidth: Constants.interactionBubbleWidth - Constants.titleMaxWidthPadding
        )
        bubble.addChild(titleLabel)
        
        let nameHitbox = createInvisibleHitbox(
            name: "btn_update_name",
            width: Constants.animalHitboxWidth,
            height: Constants.animalHitboxHeight,
            position: CGPoint(x: Constants.zero, y: Constants.animalHitboxYOffset)
        )
        bubble.addChild(nameHitbox)
        
        return bubble
    }
    
    static func createSculptureMenuBubble(parentSize: CGSize, displayName: String?) -> SKNode {
        let texture = SKTexture(imageNamed: "interaction_bubble")
        let bubble = SKSpriteNode(texture: texture)
        bubble.name = "menu_bubble"
        bubble.size = CGSize(width: Constants.interactionBubbleWidth, height: Constants.interactionBubbleHeight)
        bubble.zPosition = Constants.defaultZPosition
        bubble.position = CGPoint(x: Constants.zero, y: parentSize.height + (Constants.interactionBubbleHeight / 2) + 10)
        
        let titleLabel = createTitleLabel(
            text: displayName ?? String(localized: "Heykel"),
            fontColor: .darkGray,
            yOffset: Constants.interactionTitleYOffset,
            maxWidth: Constants.interactionBubbleWidth - Constants.titleMaxWidthPadding
        )
        bubble.addChild(titleLabel)
        
        let nameHitbox = createInvisibleHitbox(
            name: "btn_update_name",
            width: Constants.hitboxWidth,
            height: Constants.hitboxHeight,
            position: CGPoint(x: Constants.hitboxNameXOffset, y: Constants.hitboxYOffset)
        )
        bubble.addChild(nameHitbox)
        
        let moveHitbox = createInvisibleHitbox(
            name: "btn_update_pos",
            width: Constants.hitboxWidth,
            height: Constants.hitboxHeight,
            position: CGPoint(x: Constants.hitboxMoveXOffset, y: Constants.hitboxYOffset)
        )
        bubble.addChild(moveHitbox)
        
        return bubble
    }
    
    static func createMarketMenuBubble(parentSize: CGSize) -> SKNode {
        let texture = SKTexture(imageNamed: "speak_ballon")
        let bubble = SKSpriteNode(texture: texture)
        bubble.name = "market_bubble"
        bubble.size = CGSize(width: Constants.marketBubbleWidth, height: Constants.marketBubbleHeight)
        bubble.zPosition = Constants.defaultZPosition
        bubble.position = CGPoint(
            x: Constants.zero,
            y: parentSize.height + (Constants.marketBubbleHeight / Constants.halfDivider) + Constants.marketBubbleGap
        )

        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "market_bubble_icon"))
        icon.size = CGSize(width: Constants.marketIconSize, height: Constants.marketIconSize)
        icon.position = CGPoint(x: Constants.zero, y: Constants.marketIconYOffset)
        icon.zPosition = Constants.buttonLabelZPosition
        bubble.addChild(icon)

        let hitbox = createInvisibleHitbox(
            name: "btn_open_market",
            width: Constants.marketBubbleWidth,
            height: Constants.marketBubbleHeight,
            position: CGPoint(x: Constants.zero, y: Constants.zero)
        )
        bubble.addChild(hitbox)

        return bubble
    }

    static func createTalkBubble(
        parentSize: CGSize,
        parentXScale: CGFloat,
        text: String,
        width: CGFloat = Constants.talkBubbleWidth,
        minHeight: CGFloat = Constants.talkBubbleMinHeight,
        gap: CGFloat = Constants.talkBubbleGap,
        autoClose: Bool = true
    ) -> SKNode {
        let texture = SKTexture(imageNamed: "speak_ballon")
        let bubble = SKSpriteNode(texture: texture)
        bubble.name = Constants.talkBubbleName
        bubble.zPosition = Constants.defaultZPosition

        let label = createTalkLabel(text: text, maxWidth: width - Constants.talkLabelPadding)

        let dynamicHeight = max(minHeight, label.frame.height + Constants.talkVerticalPadding)
        bubble.size = CGSize(width: width, height: dynamicHeight)

        if parentXScale < Constants.zero {
            bubble.xScale = Constants.flippedScaleX
        }

        bubble.position = CGPoint(
            x: Constants.zero,
            y: parentSize.height + (dynamicHeight / Constants.halfDivider) + gap
        )
        label.position = CGPoint(x: Constants.zero, y: Constants.talkLabelYOffset)
        bubble.addChild(label)

        if autoClose {
            applyTalkAutoCloseAnimation(to: bubble)
        }

        return bubble
    }

    static func createTalkLabel(text: String, maxWidth: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = text
        label.fontSize = Constants.talkFontSize
        label.fontColor = .darkGray
        label.numberOfLines = Int(Constants.zero)
        label.preferredMaxLayoutWidth = maxWidth
        label.lineBreakMode = .byWordWrapping
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = Constants.buttonLabelZPosition
        return label
    }
    
    // MARK: - ANIMATION HELPERS
    
    static func applyAutoCloseAnimation(to bubble: SKNode, onComplete: @escaping () -> Void) {
        // Assistive-tech users dismiss the bubble explicitly by re-tapping the
        // component; a timed close would race their interaction.
        guard !A11yAnnouncer.prefersPersistentTimedUI else { return }
        let waitAction = SKAction.wait(forDuration: Constants.waitDuration)
        let fadeOut = SKAction.fadeOut(withDuration: Constants.fadeOutDuration)
        let remove = SKAction.removeFromParent()
        let updateState = SKAction.run {
            onComplete()
        }
        let autoCloseSequence = SKAction.sequence([waitAction, fadeOut, remove, updateState])
        bubble.run(autoCloseSequence, withKey: "autoCloseTimer")
    }
    
    static func applyTalkAutoCloseAnimation(to bubble: SKNode) {
        guard !A11yAnnouncer.prefersPersistentTimedUI else { return }
        let waitAction = SKAction.wait(forDuration: Constants.talkWaitDuration)
        let fadeOut = SKAction.fadeOut(withDuration: Constants.fadeOutDuration)
        let remove = SKAction.removeFromParent()
        let autoCloseSequence = SKAction.sequence([waitAction, fadeOut, remove])
        bubble.run(autoCloseSequence, withKey: "autoTalkCloseTimer")
    }
}
