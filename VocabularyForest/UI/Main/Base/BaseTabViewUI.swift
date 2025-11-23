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
    @State private var selectedTab: BaseTabTypes = .quiz
    @State private var isAddLibraryPresented = false
    
    // MARK: - VIEW

    var body: some View {
        TabView(selection: $selectedTab, content: {
            learningFeedTab
            createBookTab
            bookcaseFeedTab
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
        }.tag(BaseTabTypes.createBook).tint(.clickableButton)
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
            }.tag(BaseTabTypes.bookcases).tint(.clickableButton)
    }
    var learningFeedTab: some View {
        NavigationStack(path: $learningRouter.navPath) {
            LearningFeedUI().navigationDestination(for: LearningRouter.Destination.self) { destination in
                switch destination {
                    case .flashCard:
                    FlashCardUI(tabBar: $selectedTab).onAppear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabbarController.hideTabbar()
                            }
                        }.onDisappear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabbarController.showTabbar()
                            }
                        }
                    case .forest:
                        ForestUI().onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                tabbarController.hideTabbar()
                            }
                        }
                        .onDisappear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                tabbarController.showTabbar()
                            }
                        }
                        .ignoresSafeArea()
                        .navigationBarBackButtonHidden()
                }
            }.tabbarVisibility(visibility: tabbarController.isVisible)
        }.tabItem {
            Label("Öğrenme", systemImage: "book")
        }.tag(BaseTabTypes.quiz)
    }
    var settingsTab: some View {
        SettingsUI().tabItem {
            Label("Ayarlar", systemImage: "gearshape")
        }.tag(BaseTabTypes.settings)
    }
}
enum BaseTabTypes {
    case createBook,bookcases,quiz,forest,settings
}

