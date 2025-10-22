//
//  Text.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import Foundation
import SwiftUI

struct tvTitle: View {
    var text: String
    
    var body: some View{
        Text(text).font(.title)
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
        Text(text).font(.subheadline)
    }
}

struct tvHint: View {
    var text: String
    
    var body: some View{
        Text(text).font(.footnote)
    }
}

