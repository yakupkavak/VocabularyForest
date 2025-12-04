//
//  ForestSettingsRow.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI

func settingsRow(model: SettingsModel) -> some View {
    HStack {
        Spacer()
        Image(model.icon).resizable().scaledToFit().frame(maxWidth: 36, maxHeight: 36)
        Text(model.title).padding().foregroundStyle(.white).frame(width: UIScreen.main.bounds.width * 0.3)
        Spacer()
        
    }.padding(8).background(model.color).cornerRadius(16).overlay {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(.brown300, lineWidth: 4)
    }
}
