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
    @EnvironmentObject private var createBookRouter: CreateBookRouter
    @StateObject private var viewModel = BaseTabViewModel()
    @StateObject var tabbarController = TabBarController()
    @State private var selectedTab: Tab = .createBook
    @State private var isAddLibraryPresented = false
    
    // MARK: - VIEW

    var body: some View {
        TabView(selection: $selectedTab, content: {
            NavigationStack(path: $createBookRouter.navPath) {
                CreateBookUI().navigationDestination(for: CreateBookRouter.Destination.self) { destination in
                    switch destination {
                    case .createBookcase:
                        CreateBookcaseUI().onAppear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabbarController.hideTabbar()
                            }
                        }.onDisappear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabbarController.showTabbar()
                            }
                        }
                    }
                }
            }.tabItem {
                    Label("Feed", systemImage: "house")
            }.tag(Tab.createBook).tint(.clickableButton)
            
            NavigationStack(path: $bookcaseRouter.navPath) {
                BookcaseFeedUI().navigationDestination(for: BookcaseRouter.Destination.self) { destination in
                    switch destination {
                    case .bookcaseDetail(let bookcaseName):
                        BookcaseDetailUI(bookcaseName: bookcaseName).onAppear {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                tabbarController.hideTabbar()
                            }
                        }.onDisappear {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                tabbarController.showTabbar()
                            }
                        }
                    case .bookcaseList:
                        BookcaseFeedUI()
                    case .createBookcase:
                        CreateBookcaseUI().onAppear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabbarController.hideTabbar()
                            }
                        }.onDisappear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabbarController.showTabbar()
                            }
                        }
                    }
                }.tabbarVisibility(visibility: tabbarController.isVisible)
            }.tabItem {
                    Label("Bookcases", systemImage: "calendar")
                }.tag(Tab.bookcases).tint(.clickableButton)
            
            CreateBookUI()
                .tabItem {
                    Label("Quizes", systemImage: "calendar")
                }.tag(Tab.quiz)
            
            CreateBookUI().tabItem {
                Label("Settings", systemImage: "settings")
            }.tag(Tab.settings)
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
        case createBook,bookcases,quiz,forest,settings
    }
}

/*
 #Preview {
 BaseTabViewUI()
 }
 
 */
