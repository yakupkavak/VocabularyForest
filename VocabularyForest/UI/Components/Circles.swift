//
//  Circles.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import Foundation
import SwiftUI

struct TalkingBallons: View {
    @State private var showFirstBallon = false
    @State private var showSecondBallon = false
    @State private var showThirdBallon = false
    var foregroundColor: Color = .white
    var delayMultiplier: CGFloat = 1

    var body: some View {
        ZStack{
            if showFirstBallon{
                Circle().frame(maxWidth: 8).offset(x: +20, y: +30).foregroundStyle(foregroundColor)
            }
            if showSecondBallon{
                Circle().frame(maxWidth: 8).offset(x: +30, y: +15).foregroundStyle(foregroundColor)
            }
            if showThirdBallon{
                Circle().frame(maxWidth: 8).offset(x: +20).foregroundStyle(foregroundColor)
            }
        }.onAppear {
            withAnimation(.spring.delay(0.3 * delayMultiplier)) {
                showFirstBallon = true
            }
            withAnimation(.spring.delay(0.6 * delayMultiplier)) {
                showSecondBallon = true
            }
            withAnimation(.spring.delay(0.9 * delayMultiplier)) {
                showThirdBallon = true
            }
        }
    }
}
