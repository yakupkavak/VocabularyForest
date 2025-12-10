//
//  ForestSettingsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI
struct ForestSettingsUI: View {
    
    // MARK: - PROPERTIES
    
    var onClose: () -> Void
    @AppStorage("musicVolume") private var musicVolume: Double = 0.5
    @AppStorage("sfxVolume") private var sfxVolume: Double = 0.8
    @AppStorage("isMuted") private var isMuted: Bool = false
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    
    // MARK: - UI VIEW
    
    var body: some View {
        GamePopUpContainer(title: "Settings", onClose: onClose) {
            VStack(spacing: 24) {
                Group {
                    customSliderRow(title: "Music", icon: "music.note", value: $musicVolume)
                        .disabled(isMuted)
                        .opacity(isMuted ? 0.5 : 1.0)
                    
                    customSliderRow(title: "SFX", icon: "speaker.wave.2.fill", value: $sfxVolume)
                        .disabled(isMuted)
                        .opacity(isMuted ? 0.5 : 1.0)
                    
                    customToggleRow(title: "Mute All", icon: "speaker.slash.fill", isOn: $isMuted)
                }
                Divider().background(Color.white.opacity(0.5))
                Group {
                    customToggleRow(title: "Haptics", icon: "iphone.radiowaves.left.and.right", isOn: $isHapticsEnabled)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
