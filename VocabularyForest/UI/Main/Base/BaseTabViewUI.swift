//
//  BaseTabViewUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI

struct BaseTabViewUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject private var viewModel = BaseTabViewModel()
    @StateObject var tabbarController = TabBarController()
    @State private var selectedTab: Tab = .feed
    @State private var isAddLibraryPresented = false
    
    // MARK: - VIEW

    var body: some View {
        TabView(selection: $selectedTab, content: {
            VocabularyMainUI()
                .tabItem {
                    Label("Feed", systemImage: "house")
                }.tag(Tab.feed)
            
            VocabularyMainUI()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }.tag(Tab.history)
            
            VocabularyMainUI().tabItem {
                Label("Settings", systemImage: "settings")
            }.tag(Tab.user)
        })
        .onAppear {
            print("BaseTabViewUI appeared. ViewModel: \(viewModel)")
        }
        .navigationBarBackButtonHidden()
        .accentColor(.blue)
        .fullScreenCover(isPresented: $isAddLibraryPresented) {
            AddLibraryUI(isPresenting: $isAddLibraryPresented)
        }
        .background(.backgroundSystem)
    }
}

extension BaseTabViewUI {
    enum Tab {
        case feed,history,task,tree,user
    }
}

/*
 #Preview {
 BaseTabViewUI()
 }
 
 */
