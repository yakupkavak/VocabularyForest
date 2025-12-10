//
//  Animation.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.10.2025.
//

import Foundation
import SwiftUI

extension Animation {
    static func ripple() -> Animation {
        Animation.spring(dampingFraction: 0.5)
            .speed(2)
    }
}
