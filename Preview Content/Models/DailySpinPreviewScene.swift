#if DEBUG
//
//  DailySpinPreviewScene.swift
//  VocabularyForest
//
//  Created by Codex on 7.07.2026.
//

import SwiftUI
import YKSpinWheel

struct DailySpinPreviewScene: View {
    private let models = DailySpinPreviewDataSource.makeModels()
    
    var body: some View {
        ZStack {
            Image("sky_decor")
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .overlay(Color.black.opacity(0.55))
            
            if models.isEmpty {
                Text("Daily Spin preview data could not be loaded.")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(24)
            } else {
                DailySpinUI(
                    models: models,
                    isVisible: .constant(true),
                    nextSpinTime: .constant(nil),
                    onRewardClaimed: { _ in }
                )
            }
        }
        .frame(width: 390, height: 844)
        .clipped()
    }
}

#Preview {
    DailySpinPreviewScene()
}
#endif
