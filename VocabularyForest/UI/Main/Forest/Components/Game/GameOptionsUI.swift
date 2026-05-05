//
//  GameOptionsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI

enum GameOptionType: Codable {
    case resume
    case settings
    case home
}

struct GameOptionsUI: View {
    var onResume: () -> Void
    var onSettings: () -> Void
    var onHome: () -> Void
    var onClose: () -> Void
    
    private let options = [
        SettingsModel<SettingType>(title: "Resume", icon: "right_icon", color: .brown500, type: .resume),
        SettingsModel(title: "Settings", icon: "settings_button", color: .brown500, type: .settings),
        SettingsModel(title: "Home", icon: "exit_button", color: .brown500, type: .home)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            GamePopUpContainer(title: "Options", onClose: onClose, screenWidth: geometry.size.width) {
                VStack(spacing: 12) {
                    ForEach(options, id: \.title) { model in
                        settingsRow(model: model)
                            .onTapGesture {
                                switch model.type {
                                case .resume:   onResume()
                                case .settings: onSettings()
                                case .home:     onHome()
                                case .info:
                                    print("")
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
