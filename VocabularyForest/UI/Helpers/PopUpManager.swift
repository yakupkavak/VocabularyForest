//
//  PopUpManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.04.2026.
//

import SwiftUI
import Combine

// MARK: - POPUP MANAGER

class PopupManager: ObservableObject {
    static let shared = PopupManager()
    
    @Published var isPresented: Bool = false
    @Published var currentPopup: AnyView? = nil
    
    private init() {}
    
    func show<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        DispatchQueue.main.async {
            self.currentPopup = AnyView(content())
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.isPresented = true
            }
        }
    }
    
    func dismiss() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isPresented = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.currentPopup = nil
            }
        }
    }
}

// MARK: - POPUP MODIFIER

struct GlobalPopupModifier: ViewModifier {
    @ObservedObject private var manager = PopupManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(manager.isPresented)
                // .disabled does not stop VoiceOver from reading the background;
                // hiding it keeps the cursor inside the popup.
                .accessibilityHidden(manager.isPresented)

            if manager.isPresented, let popup = manager.currentPopup {
                Color.black
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                popup
                    .a11yModal(onEscape: { manager.dismiss() })
                    // .container only: keyboard safe area stays active so popups avoid the keyboard
                    .ignoresSafeArea(.container)
                    .zIndex(2)
                    .transition(.move(edge: .bottom))
            }
        }
    }
}

// MARK: - VIEW EXTENSION

extension View {
    func withGlobalPopup() -> some View {
        self.modifier(GlobalPopupModifier())
    }
}
