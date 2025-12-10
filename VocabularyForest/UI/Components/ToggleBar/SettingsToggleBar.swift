//
//  SettingsToggleBar.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SwiftUI

func customToggleRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
    HStack {
        Image(systemName: icon)
            .foregroundStyle(.white)
            .frame(width: 24)
        Text(title)
            .foregroundStyle(.white)
            .font(.headline)
        Spacer()
        Toggle("", isOn: isOn)
            .labelsHidden()
            .tint(Color.green)
    }
}
