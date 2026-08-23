//
//  AnimatedGradientView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.06.2026.
//

import SwiftUI

struct AnimatedGradientView: View {
    
    // MARK: - PRIVATE PROPERTIES
    
    @State private var isAnimating = false
    
    // MARK: - PROPERTIES
    
    let colors: [Color]
    let time: Double = 4.0
    
    // MARK: - VIEW
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: colors,
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: geo.size.height)
                .offset(y: isAnimating ? -geo.size.height : 0) // ekran boyutu kadar yukarıya alıyoruz

                LinearGradient(
                    colors: colors,
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: geo.size.height)
                .offset(y: isAnimating ? 0 : geo.size.height)
            }
            .onAppear {
                withAnimation(.linear(duration: time).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    let colors = [Color.blue, Color.white, Color.pink, Color.blue]
    AnimatedGradientView(colors: colors)
}
