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
    @EnvironmentObject private var learningRouter: LearningRouter
    @StateObject private var viewModel = BaseTabViewModel()
    @StateObject var tabbarController = TabBarController()
    @State private var selectedTab: Tab = .createBook
    @State private var isAddLibraryPresented = false
    
    // MARK: - VIEW

    var body: some View {
        TabView(selection: $selectedTab, content: {
            createBookTab
            bookcaseFeedTab
            learningFeedTab
            settingsTab
        })
        .navigationBarBackButtonHidden()
        .accentColor(.logoGreen)
        .background(.backgroundSystem)
    }
}
extension BaseTabViewUI {
    var createBookTab: some View {
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
                Label("Kelime", systemImage: "plus.app")
        }.tag(Tab.createBook).tint(.clickableButton)
    }
    var bookcaseFeedTab: some View {
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
                Label("Kitaplık", systemImage: "books.vertical")
            }.tag(Tab.bookcases).tint(.clickableButton)
    }
    var learningFeedTab: some View {
        NavigationStack(path: $learningRouter.navPath) {
            LearningFeedUI().navigationDestination(for: LearningRouter.Destination.self) { destination in
                switch destination {
                    case .flashCard:
                        FlashCardUI().onAppear {
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
            Label("Öğrenme", systemImage: "book")
        }.tag(Tab.quiz)
    }
    var settingsTab: some View {
        SettingsUI().tabItem {
            Label("Ayarlar", systemImage: "gearshape")
        }.tag(Tab.settings)
    }
}

extension BaseTabViewUI {
    enum Tab {
        case createBook,bookcases,quiz,forest,settings
    }
}
