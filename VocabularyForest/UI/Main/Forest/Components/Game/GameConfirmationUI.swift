//
//  Untitled.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI

struct GameConfirmationUI: View {
    
    // MARK: - PROPERTIES
    
    var title: String
    var message: String?
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    // MARK: - UI VIEW
    
    var body: some View {
        VStack() {
            ZStack {
                Image("title_header").resizable().scaledToFit().frame(height: 50)
                Text(LocalizedStringKey(title))
                    .foregroundStyle(.white)
                    .scaledFont(size: 24, weight: .bold)
            }
            Text(LocalizedStringKey(message ?? ""))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .scaledFont(size: 18, weight: .medium)
                .padding()
            HStack(spacing: 20) {
                Button {
                    onCancel()
                } label: {
                    Text("No")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 44)
                        .background(Color.red.opacity(0.4))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.5), lineWidth: 2)
                        )
                }
                Button {
                    onConfirm()
                } label: {
                    Text("Yes")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 44)
                        .background(Color.green.opacity(0.4))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.5), lineWidth: 2)
                        )
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
        .frame(width: UIScreen.main.bounds.width * 0.7)
    }
}

#Preview {
    GameConfirmationUI(title: "Emin misin", message: "yakup") {
    } onCancel: {
    }

}
