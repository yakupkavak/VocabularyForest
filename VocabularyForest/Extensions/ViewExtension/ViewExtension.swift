//
//  ViewExtension.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 8.10.2025.
//

import Foundation
import SwiftUI

extension View {
    func getRect() -> CGRect {
        UIScreen.main.bounds
    }
    func tabbarVisibility(visibility: Bool) -> some View{
        self.toolbar(visibility ? .visible : .hidden, for: .tabBar).animation(.default, value: visibility)
    }
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


