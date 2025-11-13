//
//  HalfScreenExtension.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.11.2025.
//

import SwiftUI

struct HalfScreenView<Content: View>: View {
    
    // MARK: PROPERTIES
    
    let view: Content
    var heightRatio: CGFloat = 0.5
    
    // MARK: UI
    
    init(heightRatio: CGFloat = 0.5, @ViewBuilder content: () -> Content) {
        self.heightRatio = heightRatio
        self.view = content()
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                view.frame(width: geo.size.width, height: geo.size.height * heightRatio,
                                               alignment: .center)
                Spacer()
            }
        }
    }
}
