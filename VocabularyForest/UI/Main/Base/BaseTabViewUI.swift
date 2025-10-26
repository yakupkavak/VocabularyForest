//
//  BaseTabViewUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI

struct BaseTabViewUI: View {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject private var bookcaseRouter: BookcaseRouter
    @StateObject private var viewModel = BaseTabViewModel()
    @StateObject var tabbarController = TabBarController()
    @State private var selectedTab: Tab = .feed
    @State private var isAddLibraryPresented = false
    
    // MARK: - VIEW

    var body: some View {
        TabView(selection: $selectedTab, content: {
            CreateBookUI()
                .tabItem {
                    Label("Feed", systemImage: "house")
                }.tag(Tab.feed)
            
            NavigationStack(path: $bookcaseRouter.navPath) {
                BookcaseFeedUI().navigationDestination(for: BookcaseRouter.Destination.self) { destination in
                    switch destination {
                    case .bookcaseDetail(let bookcaseName):
                        BookcaseDetailUI(bookcaseName: bookcaseName)
                    case .bookcaseList:
                        BookcaseFeedUI()
                    case .createBookcase:
                        CreateBootcaseUI()
                    }
                }.tabbarVisibility(visibility: tabbarController.isVisible)
            }.tabItem {
                    Label("Bookcases", systemImage: "calendar")
                }.tag(Tab.history)
            
            CreateBookUI()
                .tabItem {
                    Label("Quizes", systemImage: "calendar")
                }.tag(Tab.history)
            
            CreateBookUI().tabItem {
                Label("Settings", systemImage: "settings")
            }.tag(Tab.user)
        })
        .onAppear {
            print("BaseTabViewUI appeared. ViewModel: \(viewModel)")
        }
        .navigationBarBackButtonHidden()
        .accentColor(.blue)
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
