//
//  ZIndexHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.01.2026.
//

import Foundation

func getZIndex(yPosition: CGFloat) -> Double {
    30.0 - (yPosition * 10.0)
}
