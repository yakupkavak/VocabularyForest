//
//  BaseTabViewUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI
import DependencyContainer

struct BaseTabViewUI: View {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject private var bookcaseRouter: BookcaseRouter
    @EnvironmentObject private var createBookRouter: CreateBookRouter
    @EnvironmentObject private var learningRouter: LearningRouter
    @EnvironmentObject private var tabBarController: TabBarController
    @EnvironmentObject private var coordinator: VocabularyForestCoordinator
    @StateObject private var viewModel = BaseTabViewModel()
    @State private var isAddLibraryPresented = false

    // MARK: - INIT

    init() {
        // UIKit only uses the transparent scroll-edge appearance once a list is scrolled to its
        // bottom; while content passes under the bar it falls back to a translucent material that
        // reads lighter than the page. Pinning both appearances to the app background keeps the
        // tab bar flush with it at every scroll offset.
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .backgroundSystem
        tabBarAppearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    // MARK: - VIEW

    var body: some View {
        TabView(selection: $tabBarController.selectedTab, content: {
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
            coordinator.startCreateBookUI().navigationDestination(for: CreateBookRouter.Destination.self) { destination in
                switch destination {
                case .bookcaseList:
                    coordinator .startBookcaseFeedUI().onAppear {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            tabBarController.hideTabbar()
                        }
                    }.onDisappear {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            tabBarController.showTabbar()
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
            coordinator.startBookcaseFeedUI().navigationDestination(for: BookcaseRouter.Destination.self) { destination in
                switch destination {
                case .bookcaseDetail(let bookcaseName, let learningCode, let meaningCode):
                    coordinator.startBookcaseDetailUI(bookcaseName: bookcaseName, learningLanguage: learningCode, meaningLanguage: meaningCode)
                        .toolbar(.hidden, for: .tabBar)
                case .bookcaseList:
                    coordinator.startBookcaseFeedUI()
                case .createBookcase:
                    coordinator.startCreateBookcaseUI()
                case .bookcasePacket :
                    coordinator.startBookcasePacketsUI()
                        .navigationBarBackButtonHidden()
                        .toolbar(.hidden, for: .tabBar)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabBarController.hideTabbar()
                            }
                        }.onDisappear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                tabBarController.showTabbar()
                            }
                        }
                }
            }.tabbarVisibility(visibility: tabBarController.isVisible)
        }
        .tabItem {
                Label("Kitaplık", systemImage: "books.vertical")
            }.tag(BaseTabTypes.bookcases).tint(.clickableButton)
    }
    var learningFeedTab: some View {
        NavigationStack(path: $learningRouter.navPath) {
            coordinator.startLearningFeedUI().navigationDestination(for: LearningRouter.Destination.self) { destination in
                switch destination {
                    case .forest:
                    coordinator.startForestUI()
                        .ignoresSafeArea()
                        .navigationBarBackButtonHidden()
                        .toolbar(.hidden, for: .tabBar)
                case .game(let option, let mode, let level, let bookcase):
                    coordinator.startBattleUI(gameType: option, battleMode: mode, gameLevel: level, selectedBookcase: bookcase)
                    .ignoresSafeArea()
                    .navigationBarBackButtonHidden()
                    .toolbar(.hidden, for: .tabBar)
                }
            }
        }.tabItem {
            Label("Öğrenme", systemImage: "book")
        }.tag(BaseTabTypes.quiz)
    }
    var settingsTab: some View {
        coordinator.startSettingsUI()
            .tabItem {
            Label("Ayarlar", systemImage: "gearshape")
        }.tag(BaseTabTypes.settings)
    }
}
enum BaseTabTypes {
    case createBook,bookcases,quiz,forest,settings
}
