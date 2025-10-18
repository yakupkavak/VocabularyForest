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
    var imageHead: String?
    var imageFoot: String?
    
    // MARK: - VIEW
    
    var body: some View {
        HStack{
            TextField(placeholder, text: $userInput).padding()               .textFieldStyle(PlainTextFieldStyle())
        }.padding()
            .background(Color.white)
            .border(isSelected ? .selectedBorder : .gray)
            .overlay(alignment: .topLeading){
                Text(title).padding(8).font(.system(size: 20, weight: .medium)).background(.backgroundSystem).offset(x: 28, y: -20)
            }
            .overlay(alignment: .topTrailing) {
                Image(imageHead ?? "").resizable().scaledToFit().frame(width: 50).offset(x: -20,y: -23)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(imageFoot ?? "").resizable().scaledToFit().frame(width: 30).offset(x: -30,y: 7)
            }
    }
}

#Preview {
    @State var input = ""
    @State var selected = false
    
    VStack {
        VocabularyTextField(userInput: $input, isSelected: $selected, placeholder: "English word", title: "English",imageHead: "elephanthead", imageFoot: "elephantfoot")
    }.frame(minHeight: 0, maxHeight: .infinity).padding()

}
