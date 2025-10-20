//
//  VocabularyTextField.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI

struct VocabularyTextField: View {
    
    // MARK: - PROPERTIES
    
    @Binding var userInput: String
    @Binding var isSelected: Bool
    var placeholder: String
    var title: String
    var imageHead: String? = nil
    var imageFoot: String? = nil
    
    // MARK: - VIEW
    
    var body: some View {
        TextField(placeholder, text: $userInput)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .textFieldStyle(PlainTextFieldStyle())
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .selectedBorder : .gray, lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading){
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .background(
                        VStack(spacing: 0) {
                            Color.backgroundSystem
                                .frame(height: 12)
                            Color.white
                        }
                    )
                    .offset(x: 16, y: -12)
            }
            .overlay(alignment: .topTrailing) {
                Image(imageHead ?? "")
                    .resizable().scaledToFit().frame(width: 50)
                    .offset(x: -20,y: -23)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(imageFoot ?? "")
                    .resizable().scaledToFit().frame(width: 30)
                    .offset(x: -30,y: 7)
            }
    }
}

#Preview {
    @State var input = ""
    @State var selected = false
    
    VStack {
        VocabularyTextField(userInput: $input, isSelected: $selected, placeholder: "English word", title: "English",imageHead: "elephanthead", imageFoot: "elephantfoot")
    }.frame(minHeight: 0, maxHeight: .infinity).padding().background(.backgroundSystem)
    
}
