//
//  SparklesView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.04.2026.
//

import SwiftUI

// MARK: - SPARKLES VIEW

struct SparklesView: View {
    @State private var isAnimating = false
    let spreadDiameter: CGFloat
    let primaryColor: Color
    let secondaryColor: Color
    private let particleCount = 24
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                    .resizable()
                    .foregroundStyle(index.isMultiple(of: 2) ? primaryColor : secondaryColor)
                    .frame(width: sparkleSize(for: index), height: sparkleSize(for: index))
                    .offset(x: sparkleXOffset(for: index), y: sparkleYOffset(for: index))
                    .scaleEffect(isAnimating ? 1.18 : 0.72)
                    .opacity(isAnimating ? 0.85 : 0.35)
                    .shadow(color: .white.opacity(0.8), radius: 6)
                    .blur(radius: isAnimating ? 1 : 0)
                    .animation(
                        .easeInOut(duration: sparkleDuration(for: index))
                            .repeatForever(autoreverses: true)
                            .delay(sparkleDelay(for: index)),
                        value: isAnimating
                    )
            }
        }
        .frame(width: spreadDiameter, height: spreadDiameter)
        .compositingGroup()
        .allowsHitTesting(false)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - PRIVATE HELPERS

private extension SparklesView {
    func sparkleAngleInRadians(for index: Int) -> Double {
        let degrees = Double(index) * (360.0 / Double(particleCount))
        return degrees * .pi / 180.0
    }
    
    func sparkleDistance(for index: Int) -> CGFloat {
        let minDistance = spreadDiameter * 0.20
        let maxDistance = spreadDiameter * 0.50
        let bandCount = 6
        let step = (maxDistance - minDistance) / CGFloat(bandCount - 1)
        return minDistance + (CGFloat(index % bandCount) * step)
    }
    
    func sparkleXOffset(for index: Int) -> CGFloat {
        let angle = sparkleAngleInRadians(for: index)
        return CGFloat(cos(angle)) * sparkleDistance(for: index)
    }
    
    func sparkleYOffset(for index: Int) -> CGFloat {
        let angle = sparkleAngleInRadians(for: index)
        return CGFloat(sin(angle)) * sparkleDistance(for: index)
    }
    
    func sparkleSize(for index: Int) -> CGFloat {
        CGFloat(16 + (index % 4) * 4)
    }
    
    func sparkleDuration(for index: Int) -> Double {
        1.1 + (Double(index % 5) * 0.15)
    }
    
    func sparkleDelay(for index: Int) -> Double {
        Double(index) * 0.06
    }
}
