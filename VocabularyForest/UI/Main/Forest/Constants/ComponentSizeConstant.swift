//
//  ComponentSizeConstant.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.01.2026.
//

import UIKit

enum ComponentSizeConstant {
    static let sculptureHeight = UIScreen.main.bounds.height * 0.2
    static let animalHeight = UIScreen.main.bounds.height * 0.1
    static let plantHeight = UIScreen.main.bounds.height * 0.15

    /// Resolves a forest node's size from the rewards_config ratios (fractions of
    /// screen height). A missing heightRatio falls back to the category default,
    /// a missing widthRatio to the texture's own aspect ratio.
    static func nodeSize(
        textureSize: CGSize,
        widthRatio: CGFloat?,
        heightRatio: CGFloat?,
        defaultHeight: CGFloat
    ) -> CGSize {
        let screenHeight = UIScreen.main.bounds.height
        let height = heightRatio.map { screenHeight * $0 } ?? defaultHeight
        let width: CGFloat
        if let widthRatio {
            width = screenHeight * widthRatio
        } else if textureSize.height > 0 {
            width = height * (textureSize.width / textureSize.height)
        } else {
            width = height
        }
        return CGSize(width: width, height: height)
    }
}
