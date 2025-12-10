//
//  ForestSettingsRow.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI

func settingsRow<T: Hashable>(model: SettingsModel<T>) -> some View {
    HStack {
        Spacer()
        Image(model.icon).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width * 0.12, height: UIScreen.main.bounds.width * 0.12)
        Text(model.title).padding().foregroundStyle(.white).frame(width: UIScreen.main.bounds.width * 0.4, alignment: .leading)
        Spacer()
    }.padding(8).background(model.color).cornerRadius(16).overlay {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(.brown300, lineWidth: 4)
    }
}
