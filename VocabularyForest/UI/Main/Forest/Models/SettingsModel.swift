//
//  SettingsModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SwiftUI

struct SettingsModel: Hashable {
    let title: String
    let icon: String
    let color: Color
    let type: SettingType
}

enum SettingType {
    case resume
    case settings
    case home
}
