//
//  GetSafeAreaInsets.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.12.2025.
//

import SwiftUI

// Source - https://stackoverflow.com/a
// Posted by Mirko, modified by community. See post 'Timeline' for change history
// Retrieved 2025-12-09, License - CC BY-SA 4.0

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes.lazy
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }
}

extension EnvironmentValues {
    @Entry var safeAreaInsets: EdgeInsets =
        UIApplication.shared.keyWindow?.safeAreaInsets.edgeInsets ?? EdgeInsets()
}

extension UIEdgeInsets {
    var edgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
