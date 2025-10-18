//
//  AddLibraryUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI

struct AddLibraryUI: View {
    
    //MARK: - PROPERTIES
    
    @Binding var isPresenting: Bool
    
    //MARK: - VIEW
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    @State var isPresenting = true
    AddLibraryUI(isPresenting: $isPresenting)
}
