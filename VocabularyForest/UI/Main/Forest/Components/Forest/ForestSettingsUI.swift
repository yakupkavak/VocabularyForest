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
        GeometryReader { geometry in
            GamePopUpContainer(title: "Settings", onClose: onClose, screenWidth: geometry.size.width) {
                VStack(spacing: 24) {
                    Group {
                        customSliderRow(title: String(localized: "Music"), icon: "music.note", value: $musicVolume)
                            .disabled(isMuted)
                            .opacity(isMuted ? 0.5 : 1.0)
                        
                        customSliderRow(title: String(localized: "SFX"), icon: "speaker.wave.2.fill", value: $sfxVolume)
                            .disabled(isMuted)
                            .opacity(isMuted ? 0.5 : 1.0)
                        
                        customToggleRow(title: String(localized: "Mute All"), icon: "speaker.slash.fill", isOn: $isMuted)
                    }
                    Divider().background(Color.white.opacity(0.5))
                    Group {
                        customToggleRow(title: String(localized: "Haptics"), icon: "iphone.radiowaves.left.and.right", isOn: $isHapticsEnabled)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
    }
}
