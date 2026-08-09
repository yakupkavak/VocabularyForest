//
//  GamePopUpContainer.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI

struct GamePopUpContainer<Content: View>: View {
    
    let title: String
    let onClose: () -> Void
    let screenWidth: CGFloat
    let content: Content
    
    init(title: String, onClose: @escaping () -> Void, screenWidth: CGFloat ,@ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.screenWidth = screenWidth
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .modifier(TitleBackground())
            .padding(.bottom, 10)
            content
        }
        .padding(24)
        .background(Color.brown.opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("brown300"), lineWidth: 4)
        )
        .frame(maxWidth: screenWidth * 0.7)
        .fixedSize(horizontal: true, vertical: false)
        .overlay(alignment: .topTrailing) {
            Button {
                onClose()
            } label: {
                Image("close_button")
                    .resizable()
                    .frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
                    .accessibilityLabel(String(localized: "a11y_close"))
            }
        }
        .zIndex(4.0)
    }
}
