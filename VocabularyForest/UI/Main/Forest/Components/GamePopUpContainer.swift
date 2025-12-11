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
    let content: Content
    
    init(title: String, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .foregroundStyle(.white)
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Image("title_header").resizable())
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
        .frame(width: UIScreen.main.bounds.width * 0.7)
        .overlay(alignment: .topTrailing) {
            Button {
                onClose()
            } label: {
                Image("close_button")
                    .resizable()
                    .frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
            }
        }
        .zIndex(4.0)
    }
}
