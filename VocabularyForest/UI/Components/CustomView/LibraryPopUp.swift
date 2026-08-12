//
//  LibraryPopUp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.07.2026.
//

import SwiftUI

struct LibraryPopUp: View{
     
    // MARK: - PROPERTIES
    
    var titleText: String
    var descriptionText: String?
    var onConfirm: () -> Void
    var onClose: () -> Void
    var confirmText: String
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: 20) {
            Text(titleText)
                .foregroundStyle(.title)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0,maxWidth: .infinity,alignment: .leading)
                .fontWeight(.bold)
            if let descriptionText {
                Text(descriptionText).foregroundStyle(.forestText).scaledFont(size: 14).multilineTextAlignment(.leading)
            }
            HStack(alignment: .center) {
                Button {
                    onConfirm()
                    onClose()
                } label: {
                    HStack {
                        Image("watch_icon")
                            .resizable()
                            .frame(maxWidth: 36, maxHeight: 36)
                        Spacer()
                        Text(confirmText)
                        Spacer()
                    }.modifier(ForestButtonBackground(color: .logoGreen))
                }
            }
        }
        .padding(24)
        .background(Color.backgroundSystem)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("brown300"), lineWidth: 4)
        )
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
        }.frame(maxWidth: UIScreen.main.bounds.width * 0.7)
            .overlay(alignment: .topLeading, content: {
                Image(getRandomAnimalModel().head)
                    .resizable()
                    .frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
                
            })
        .zIndex(4.0)
    }
    
}

#Preview {
    @State var bool: Bool = false
    
    LibraryPopUp(titleText: "Download Vocabulary", descriptionText: "You can download a vocabulary by watching a Video. Would you like to watch a Video?", onConfirm: { }, onClose: { }, confirmText: "Watch the Video")
}
