//
//  StringExtesion.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.06.2026.
//

import SwiftUI

extension String {
    /// Converts String to Color 
    /// Usage Example: "#FF5733".color or "FF5733".color
    var color: Color {
        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let red, green, blue, alpha: Double
        switch hexSanitized.count {
        case 6:
            red = Double((rgb >> 16) & 0xFF) / 255.0
            green = Double((rgb >> 8) & 0xFF) / 255.0
            blue = Double(rgb & 0xFF) / 255.0
            alpha = 1.0
        case 8:
            red = Double((rgb >> 24) & 0xFF) / 255.0
            green = Double((rgb >> 16) & 0xFF) / 255.0
            blue = Double((rgb >> 8) & 0xFF) / 255.0
            alpha = Double(rgb & 0xFF) / 255.0
        default:
            return Color.black
        }
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
