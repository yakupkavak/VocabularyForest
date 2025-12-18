//
//  Text.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import Foundation
import SwiftUI

struct TitleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundStyle(.white)
            .font(.system(size: 20, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Image("title_header").resizable())
    }
}

struct ForestButtonBackground: ViewModifier {
    
    var color: Color
    
    func body(content: Content) -> some View {
        content.foregroundStyle(.white)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(color)
            ).overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}

struct tvMainTitle: View {
    var text: String
    
    var body: some View{
        Text(text).font(.system(size: 28, weight: .bold)).foregroundStyle(.brown300)
    }
}

struct tvTitle: View {
    var text: String
    
    var body: some View{
        Text(text).font(.system(size: 20, weight: .bold)).foregroundStyle(.brown300)
    }
}
 
struct tvDefault: View {
    var text: String
    var color: Color = .primary
    var body: some View{
        Text(text).font(.callout).foregroundStyle(color)
    }
}

struct tvSubtitle: View {
    var text: String
    
    var body: some View{
        Text(text).font(.system(size: 20, weight: .regular))
    }
}

struct tvHint: View {
    var text: String
    
    var body: some View{
        Text(text).font(.footnote)
    }
}
struct tvGrayHint: View {
    var text: String
    
    var body: some View{
        Text(text).font(.footnote).foregroundStyle(.gray)
    }
}

