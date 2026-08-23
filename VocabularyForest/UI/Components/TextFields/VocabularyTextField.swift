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
    @Binding var isEmpty: Bool
    var placeholder: String
    var title: String? = nil
    var imageHead: String? = nil
    var imageFoot: String? = nil
    
    // MARK: - VIEW
    
    var body: some View {
        // Vertical axis lets long placeholders and accessibility text sizes wrap
        // instead of clipping inside the fixed single-line height.
        TextField(placeholder, text: $userInput, axis: .vertical)
            .a11yFieldLabel(title)
            .padding(.vertical, 16)
            .padding(.horizontal)
            .lineLimit(1...3)
            .foregroundStyle(.logoGreen)
            .textFieldStyle(PlainTextFieldStyle())
            .background(Color.textfieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEmpty ? .errorBorder : (isSelected ? .selectedBorder : .gray), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading){
                if let title {
                    Text(title)
                        .a11yDecorative()
                        .scaledFont(size: 20, weight: .bold)
                        .foregroundStyle(.textfieldHeader)
                        .background(
                            VStack(spacing: 0) {
                                Color.backgroundSystem
                                    .frame(height: 12)
                                Color.textfieldBackground
                            }
                        )
                        .offset(x: 16, y: -12)
                }
            }
            .overlay(alignment: .topTrailing) {
                Image(imageHead ?? "")
                    .resizable().scaledToFit().frame(width: 50)
                    .offset(x: -20,y: -23)
                    .a11yDecorative()
            }
            .overlay(alignment: .bottomTrailing) {
                Image(imageFoot ?? "")
                    .resizable().scaledToFit().frame(width: 30)
                    .offset(x: -30,y: 7)
                    .a11yDecorative()
            }
    }
}

#Preview {
    @State var input = ""
    @State var selected = false
    
    VStack {
        VocabularyTextField(userInput: $input, isSelected: $selected, isEmpty: .constant(true), placeholder: "English word", title: "English",imageHead: "elephanthead", imageFoot: "elephantfoot")
    }.frame(minHeight: 0, maxHeight: .infinity).padding().background(.backgroundSystem)
        .preferredColorScheme(.dark)
    
}
