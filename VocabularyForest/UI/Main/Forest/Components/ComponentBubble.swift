//
//  ComponentBubble.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.03.2026.
//

import SpriteKit

struct ComponentBubble {
    
    enum Constants {
        static let zero: CGFloat = 0.0
        
        static let defaultBubbleWidth: CGFloat = 120
        static let defaultBubbleHeight: CGFloat = 80
        static let sculptureBubbleWidth: CGFloat = 140
        static let sculptureBubbleHeight: CGFloat = 90
        
        static let talkBubbleWidth: CGFloat = 180
        static let talkLabelPadding: CGFloat = 10
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
        
        static let defaultCornerRadius: CGFloat = 10
        static let defaultAlpha: CGFloat = 0.95
        static let defaultLineWidth: CGFloat = 2
        static let talkLineWidth: CGFloat = 3
        static let defaultZPosition: CGFloat = 100
        static let defaultYOffset: CGFloat = 40
        
        static let titleFontSize: CGFloat = 16
        static let titleYOffset: CGFloat = 15
        
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
    
    static func createBaseBubble(width: CGFloat, height: CGFloat, parentSize: CGSize, strokeColor: UIColor = .black, lineWidth: CGFloat = Constants.defaultLineWidth) -> SKShapeNode {
        let bubble = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: Constants.defaultCornerRadius)
        bubble.fillColor = .brown500.withAlphaComponent(Constants.defaultAlpha)
        bubble.strokeColor = strokeColor
        bubble.lineWidth = lineWidth
        bubble.zPosition = Constants.defaultZPosition
        
        bubble.position = CGPoint(x: Constants.zero, y: parentSize.height + Constants.defaultYOffset)
        
        return bubble
    }
    
    static func createTitleLabel(text: String) -> SKLabelNode {
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = text
        titleLabel.fontSize = Constants.titleFontSize
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: Constants.zero, y: Constants.titleYOffset)
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
    
    static func createAnimalMenuBubble(parentSize: CGSize, displayName: String?) -> SKShapeNode {
        let bubble = createBaseBubble(width: Constants.defaultBubbleWidth, height: Constants.defaultBubbleHeight, parentSize: parentSize)
        bubble.name = "menu_bubble"
        
        let titleLabel = createTitleLabel(text: displayName ?? String(localized: "Animal"))
        bubble.addChild(titleLabel)
        
        let headerSeparator = SKShapeNode(rectOf: CGSize(width: Constants.defaultBubbleWidth - Constants.separatorWidthReduction, height: Constants.separatorHeight))
        headerSeparator.fillColor = .black.withAlphaComponent(Constants.separatorAlpha)
        headerSeparator.strokeColor = .clear
        headerSeparator.position = CGPoint(x: Constants.zero, y: Constants.separatorYOffset)
        bubble.addChild(headerSeparator)
        
        let buttonSize = CGSize(width: Constants.buttonWidth, height: Constants.buttonHeight)
        let buttonHitBox = SKShapeNode(rectOf: buttonSize, cornerRadius: Constants.buttonCornerRadius)
        buttonHitBox.fillColor = .white.withAlphaComponent(Constants.buttonAlpha)
        buttonHitBox.strokeColor = .clear
        buttonHitBox.name = "btn_update_name"
        buttonHitBox.position = CGPoint(x: Constants.zero, y: Constants.buttonYOffset)
        buttonHitBox.zPosition = Constants.buttonZPosition
        
        let btnLabel = createButtonLabel(text: String(localized: "İsim Değiştir"), name: "btn_update_name")
        btnLabel.zPosition = Constants.buttonLabelZPosition
        buttonHitBox.addChild(btnLabel)
        
        bubble.addChild(buttonHitBox)
        return bubble
    }
    
    static func createSculptureMenuBubble(parentSize: CGSize, displayName: String?) -> SKShapeNode {
        let bubble = createBaseBubble(width: Constants.sculptureBubbleWidth, height: Constants.sculptureBubbleHeight, parentSize: parentSize)
        bubble.name = "menu_bubble"
        
        let titleLabel = createTitleLabel(text: displayName ?? String(localized: "Heykel"))
        bubble.addChild(titleLabel)
        
        let headerSeparator = SKShapeNode(rectOf: CGSize(width: Constants.sculptureBubbleWidth - Constants.separatorWidthReduction, height: Constants.separatorHeight))
        headerSeparator.fillColor = .black.withAlphaComponent(Constants.separatorAlpha)
        headerSeparator.strokeColor = .clear
        headerSeparator.position = CGPoint(x: Constants.zero, y: Constants.separatorYOffset)
        bubble.addChild(headerSeparator)
        
        let nameBtn = createButtonLabel(text: String(localized: "İsim Değiştir"), name: "btn_update_name", maxWidth: Constants.defaultButtonMaxWidth)
        nameBtn.position = CGPoint(x: Constants.buttonNegXOffset, y: Constants.buttonYOffset)
        nameBtn.fontColor = .black
        bubble.addChild(nameBtn)
        
        let separator = SKShapeNode(rectOf: CGSize(width: Constants.verticalSeparatorWidth, height: Constants.verticalSeparatorHeight))
        separator.fillColor = .logoGreen
        separator.strokeColor = .logoGreen
        separator.position = CGPoint(x: Constants.zero, y: Constants.verticalSeparatorYOffset)
        bubble.addChild(separator)
        
        let posBtn = createButtonLabel(text: String(localized: "Taşı"), name: "btn_update_pos", maxWidth: Constants.defaultButtonMaxWidth)
        posBtn.position = CGPoint(x: Constants.buttonPosXOffset, y: Constants.buttonYOffset)
        posBtn.fontColor = .black
        bubble.addChild(posBtn)
        
        return bubble
    }
    
    static func createTalkBubble(parentSize: CGSize, parentXScale: CGFloat, text: String, width: CGFloat = Constants.talkBubbleWidth) -> SKShapeNode {
        
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = text
        label.fontSize = Constants.talkFontSize
        label.fontColor = .white
        label.numberOfLines = Int(Constants.zero)
        label.preferredMaxLayoutWidth = width - Constants.talkLabelPadding
        label.lineBreakMode = .byWordWrapping
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        let dynamicHeight = label.frame.height + Constants.talkVerticalPadding
        
        let bubble = createBaseBubble(width: width, height: dynamicHeight, parentSize: parentSize, strokeColor: .white, lineWidth: Constants.talkLineWidth)
        bubble.name = "talk_bubble"
        
        var isFlipped = false
        if parentXScale < Constants.zero {
            bubble.xScale = Constants.flippedScaleX
            isFlipped = true
        }
        
        label.position = CGPoint(x: Constants.zero, y: Constants.zero)
        bubble.addChild(label)
        
        var currentDotY = -(dynamicHeight / Constants.halfDivider) - Constants.talkDotInitialYOffset
        var currentDotSize = Constants.talkDotInitialSize
        
        for i in 0..<Constants.talkDotCount {
            let dot = SKShapeNode(circleOfRadius: currentDotSize / Constants.halfDivider)
            dot.fillColor = .logoGreen.withAlphaComponent(Constants.defaultAlpha)
            dot.strokeColor = .white
            dot.lineWidth = Constants.talkDotLineWidth
            
            var dotX: CGFloat = Constants.zero
            
            if i == 1 {
                let directionMultiplier: CGFloat = isFlipped ? Constants.flippedScaleX : Constants.targetScale
                dotX = Constants.talkDotXShiftMultiplier * directionMultiplier
            }
            
            dot.position = CGPoint(x: dotX, y: currentDotY)
            dot.zPosition = Constants.talkDotZPosition
            bubble.addChild(dot)
            
            currentDotSize -= Constants.talkDotSizeDecrement
            currentDotY -= (currentDotSize + Constants.talkDotVerticalSpacing)
        }
        
        applyTalkAutoCloseAnimation(to: bubble)
        
        return bubble
    }
    
    static func applyAutoCloseAnimation(to bubble: SKNode, onComplete: @escaping () -> Void) {
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
        let waitAction = SKAction.wait(forDuration: Constants.talkWaitDuration)
        let fadeOut = SKAction.fadeOut(withDuration: Constants.fadeOutDuration)
        let remove = SKAction.removeFromParent()
        let autoCloseSequence = SKAction.sequence([waitAction, fadeOut, remove])
        bubble.run(autoCloseSequence, withKey: "autoTalkCloseTimer")
    }
}
