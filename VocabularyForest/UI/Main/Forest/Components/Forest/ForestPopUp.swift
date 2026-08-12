//
//  ForestPopUp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.12.2025.
//

import SwiftUI

struct ForestPopUp: View{
     
    // MARK: - PROPERTIES
    
    var titleText: String
    var descriptionText: String?
    var onConfirm: () -> Void
    var onDenied: (() -> Void)?
    var confirmText: String
    var deniedText: String?
    @Binding var showForestPopUp: Bool
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: 20) {
            Text(titleText)
                .modifier(TitleBackground())
            .padding(.bottom, 10)
            if let descriptionText {
                Text(descriptionText).foregroundStyle(.white).scaledFont(size: 14).multilineTextAlignment(.center)
            }
            HStack(alignment: .center) {
                if let deniedText, let onDenied {
                    Button {
                        onDenied()
                    } label: {
                        Text(deniedText).modifier(ForestButtonBackground(color: .errorBorder))
                    }.padding(.horizontal, 16)
                }
                Button {
                    onConfirm()
                } label: {
                    Text(confirmText).modifier(ForestButtonBackground(color: .logoGreen))
                }
            }
        }
        .padding(24)
        .background(Color.brown.opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("brown300"), lineWidth: 4)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                showForestPopUp = false
            } label: {
                Image("close_button")
                    .resizable()
                    .frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
            }
        }.frame(maxWidth: UIScreen.main.bounds.width * 0.7)
        .zIndex(4.0)
    }
    
}

#Preview {
    @State var bool: Bool = false
    
    ForestPopUp(titleText: "Yakup", descriptionText: "Kafasdfsdafsdafsafasfsafdsafasasfsdafsdafsafasvak", onConfirm: { }, onDenied: { }, confirmText: "Kabul", deniedText: "Red", showForestPopUp: $bool)
}
