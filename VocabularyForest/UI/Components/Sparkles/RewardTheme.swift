//
//  RewardTheme.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.04.2026.
//

import SwiftUI

// MARK: - REWARD THEME MODELS

struct RewardTheme {
    let textColor: Color
    let panelColors: [Color]
    let panelStroke: Color
    let buttonColors: [Color]
    let buttonShadow: Color
    let sparklePalette: SparklePalette
}

struct SparklePalette {
    let primary: Color
    let secondary: Color
    let shadow: Color
}

// MARK: - REWARD THEME EXTENSIONS

extension QuestRewardModel {
    var theme: RewardTheme {
        switch self {
        case .gold:
            return RewardTheme(
                textColor: Color(hex: "#8B5E00"),
                panelColors: [
                    Color(hex: "#FFF5CC").opacity(0.78),
                    Color(hex: "#F4C430").opacity(0.42),
                    Color(hex: "#C88A1E").opacity(0.56)
                ],
                panelStroke: Color(hex: "#E8B83F"),
                buttonColors: [Color(hex: "#F9C940"), Color(hex: "#D99611")],
                buttonShadow: Color(hex: "#9F6400"),
                sparklePalette: SparklePalette(
                    primary: Color(hex: "#FFF1BF"),
                    secondary: Color(hex: "#FFCC4D"),
                    shadow: Color(hex: "#B67F1E")
                )
            )
        case .water:
            return RewardTheme(
                textColor: Color(hex: "#0B4F6C"),
                panelColors: [
                    Color(hex: "#E2F5FA").opacity(0.82),
                    Color(hex: "#77AFCA").opacity(0.4),
                    Color(hex: "#3A7192").opacity(0.56)
                ],
                panelStroke: Color(hex: "#5FB3D9"),
                buttonColors: [Color(hex: "#53C8E3"), Color(hex: "#288CAD")],
                buttonShadow: Color(hex: "#1F6780"),
                sparklePalette: SparklePalette(
                    primary: Color(hex: "#E7FAFF"),
                    secondary: Color(hex: "#7ADAF2"),
                    shadow: Color(hex: "#317DA0")
                )
            )
        case .diamond:
            return RewardTheme(
                textColor: Color(hex: "#0B3A64"),
                panelColors: [
                    Color(hex: "#F0FDFF").opacity(0.9),
                    Color(hex: "#8BE9F7").opacity(0.54),
                    Color(hex: "#2783D7").opacity(0.75)
                ],
                panelStroke: Color(hex: "#7BDDF2"),
                buttonColors: [Color(hex: "#4DD2FF"), Color(hex: "#2767F0")],
                buttonShadow: Color(hex: "#1D3F9F"),
                sparklePalette: SparklePalette(
                    primary: Color(hex: "#EAFDFF"),
                    secondary: Color(hex: "#72DFFF"),
                    shadow: Color(hex: "#2A67D3")
                )
            )
        case .plant:
            return RewardTheme(
                textColor: Color(hex: "#2F5D1B"),
                panelColors: [
                    Color(hex: "#F2F9CC").opacity(0.8),
                    Color(hex: "#B6D93B").opacity(0.44),
                    Color(hex: "#6D9E2F").opacity(0.56)
                ],
                panelStroke: Color(hex: "#99D04E"),
                buttonColors: [Color(hex: "#7CD347"), Color(hex: "#3A9D32")],
                buttonShadow: Color(hex: "#2C6F1E"),
                sparklePalette: SparklePalette(
                    primary: Color(hex: "#F2FFD5"),
                    secondary: Color(hex: "#A8EA6A"),
                    shadow: Color(hex: "#4D922A")
                )
            )
        case .animal:
            return RewardTheme(
                textColor: Color(hex: "#7A1F5C"),
                panelColors: [
                    Color(hex: "#FFE3F1").opacity(0.82),
                    Color(hex: "#FF8EC6").opacity(0.48),
                    Color(hex: "#8A4DFF").opacity(0.6)
                ],
                panelStroke: Color(hex: "#FF6B9D"),
                buttonColors: [Color(hex: "#58C9FF"), Color(hex: "#2D66D8")],
                buttonShadow: Color(hex: "#1E4EAA"),
                sparklePalette: SparklePalette(
                    primary: Color(hex: "#EAF7FF"),
                    secondary: Color(hex: "#67CCFF"),
                    shadow: Color(hex: "#2F67C8")
                )
            )
        case .sculpture:
            return RewardTheme(
                textColor: Color(hex: "#124734"),
                panelColors: [
                    Color(hex: "#EEFFF5").opacity(0.9),
                    Color(hex: "#7EE6B5").opacity(0.58),
                    Color(hex: "#1F9F70").opacity(0.75)
                ],
                panelStroke: Color(hex: "#37C58A"),
                buttonColors: [Color(hex: "#D8B08A"), Color(hex: "#9B6A3A")],
                buttonShadow: Color(hex: "#6F4624"),
                sparklePalette: SparklePalette(
                    primary: Color(hex: "#FFF1DF"),
                    secondary: Color(hex: "#D7AF7C"),
                    shadow: Color(hex: "#8A5E35")
                )
            )
        }
    }
}

extension ChestBountyModel {
    var sparklePalette: SparklePalette {
        switch self {
        case .gold:
            return SparklePalette(
                primary: Color(hex: "#FFF1BF"),
                secondary: Color(hex: "#FFCC4D"),
                shadow: Color(hex: "#B67F1E")
            )
        case .nature:
            return SparklePalette(
                primary: Color(hex: "#F2FFD5"),
                secondary: Color(hex: "#A6E05F"),
                shadow: Color(hex: "#4F8F2D")
            )
        case .diamond:
            return SparklePalette(
                primary: Color(hex: "#E7FAFF"),
                secondary: Color(hex: "#6AD8FF"),
                shadow: Color(hex: "#2E7AB8")
            )
        case .antique:
            return SparklePalette(
                primary: Color(hex: "#FFF1DF"),
                secondary: Color(hex: "#D7AF7C"),
                shadow: Color(hex: "#8A5E35")
            )
        }
    }
}
