//
//  SKActionAnimate.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 19.11.2025.
//

import SpriteKit

extension SKAction {
    static func animateSprite(textures: [SKTexture], timePerFrame: CGFloat) -> SKAction {
        self.animate(with: textures, timePerFrame: timePerFrame, resize: false, restore: false)
    }
}
