import SwiftUI
import Lottie

//
//  CusomE.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.12.2025.
//

struct CustomEmptyView: View {
    
    @State private var showEmptyText = false
    var emptyText: String

    var body: some View {
        VStack(spacing: 24){
            Spacer()
            tvDefault(text: emptyText, color: .brown300)
                .padding(24)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.title, lineWidth: 4)
                }.opacity(showEmptyText ? 1.0 : 0.0 )
            TalkingBallons(foregroundColor: .title, delayMultiplier: 1.5)
                .a11yDecorative()
            LottieView(animation: .named("growingPlant"))
                .playing(loopMode: .playOnce).resizable().frame(maxWidth: 250).frame(maxHeight: 300)
                .a11yDecorative()
            Spacer()
        }
        .onAppear {
            withAnimation(Animation.spring(duration: 1.0).delay(1.8)) {
                     self.showEmptyText = true
                }
        }.padding(.bottom, 32)
    }
}
