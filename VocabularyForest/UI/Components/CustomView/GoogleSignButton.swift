//
//  GoogleSign.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 8.04.2026.
//

import SwiftUI
import GoogleSignIn

struct GoogleSignInButtonView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.colorScheme = .light
        button.style = .standard
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {
    }
}
