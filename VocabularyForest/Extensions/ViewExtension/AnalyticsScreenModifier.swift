//
//  AnalyticsScreenModifier.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.08.2026.
//

import SwiftUI

// MARK: - ENVIRONMENT

private struct AnalyticsServiceKey: EnvironmentKey {
    // Noop default keeps previews and unit-tested views silent without wiring.
    static let defaultValue: AnalyticsServiceProtocol = NoopAnalyticsService()
}

extension EnvironmentValues {
    var analyticsService: AnalyticsServiceProtocol {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}

// MARK: - MODIFIER

struct AnalyticsScreenModifier: ViewModifier {

    @Environment(\.analyticsService) private var analyticsService
    let screen: AnalyticsScreen

    func body(content: Content) -> some View {
        content.onAppear {
            analyticsService.logScreen(screen)
        }
    }
}

// MARK: - HELPERS

extension View {

    func trackScreen(_ screen: AnalyticsScreen) -> some View {
        modifier(AnalyticsScreenModifier(screen: screen))
    }
}
