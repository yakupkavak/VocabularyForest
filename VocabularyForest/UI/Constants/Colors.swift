//
//  Colors.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import Foundation
import SwiftUI

struct Colors {
    static let background = Color("background_color")
    static let selectedButton = Color("selected_button")
    static let unselectedButton = Color("unselected_button")

}

let titleGradient = LinearGradient(
    colors: [
        Color(white: 0.93),
        Color(red: 255/255, green: 228/255, blue: 133/255),
        Color(red: 235/255, green: 175/255, blue: 60/255)
    ],
    startPoint: .top,
    endPoint: .bottom
)
let goldGradient = LinearGradient(
        colors: [
            Color(red: 255/255, green: 228/255, blue: 133/255),
            Color(red: 235/255, green: 175/255, blue: 60/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
