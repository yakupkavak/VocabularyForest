//
//  BottomSheet.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.04.2026.
//

import SwiftUI

struct BottomSheet<Content: View>: View {
    
    let content: Content
    let title: String?
    @Binding var isVisible: Bool
    @State var currentAnimal = getRandomAnimalModel().head
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(title: String?, isVisible: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.title = title
        self._isVisible = isVisible
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack {
                    if let title {
                        Text(title)
                            .a11yHeader()
                            .scaledFont(size: 24, weight: .heavy, design: .rounded).multilineTextAlignment(.center)
                            .foregroundStyle(.title)
                            .padding(.horizontal, 48)
                    }
                    Spacer()
                }
                content
            }
            .padding(horizontalSizeClass == .regular ? 100 : 32)
            .overlay(alignment: .topTrailing) {
                Button {
                    isVisible = false
                } label: {
                    Image(systemName: "xmark").resizable().scaledToFit()
                        .scaledFont(size: 100, weight: .heavy, design: .rounded)
                        .foregroundStyle(.title)
                        .frame(width: geo.size.width * 0.06)
                        .accessibilityLabel(String(localized: "a11y_close"))
                }.offset(x: geo.size.width * -0.07)
            }
            .padding(.top)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.brown500)
            .customCornerRadius(16, corners: [.topLeft, .topRight])
            .overlay(alignment: .topLeading) {
                Image(currentAnimal).resizable().scaledToFit().frame(height: horizontalSizeClass == .regular ? 100 : 50).offset(x: 40 ,y: horizontalSizeClass == .regular ? -50 : -25)
                    .a11yDecorative()
            }
        }
    }
}

#Preview {
    BottomSheet(title: "", isVisible: .constant(true)) {
        VStack {
            Text("Yakup")
            Text("Yakup")
        }
    }
}
