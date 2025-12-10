//
//  ContentView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import CoreData

struct MainView: View {
    
    //MARK: - Properties
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    //MARK: - View
    
    var body: some View {
        if hasCompletedOnboarding {
            BaseTabViewUI().background(.backgroundSystem)
        }else {
            OnboardingUI()
        }
    }
}

#Preview {
    MainView()
}
