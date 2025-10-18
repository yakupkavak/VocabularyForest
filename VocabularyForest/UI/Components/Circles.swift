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

    var body: some View {
        ZStack{
            if showFirstBallon{
                Circle().frame(maxWidth: 8).offset(x: +20, y: +30).foregroundStyle(.white)
            }
            if showSecondBallon{
                Circle().frame(maxWidth: 8).offset(x: +30, y: +15).foregroundStyle(.white)
            }
            if showThirdBallon{
                Circle().frame(maxWidth: 8).offset(x: +20).foregroundStyle(.white)
            }
        }.onAppear {
            withAnimation(.spring.delay(0.3)) {
                showFirstBallon = true
            }
            withAnimation(.spring.delay(0.6)) {
                showSecondBallon = true
            }
            withAnimation(.spring.delay(0.9)) {
                showThirdBallon = true
            }
        }
    }
}
