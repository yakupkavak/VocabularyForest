//
//  QuizRowUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//

import SwiftUI

struct QuizRowUI: View {
    
    // MARK: - PROPERTIES
    
    var quizModel: QuizRowModel
    var height: CGFloat
    var onClick: (QuizType) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - UI

    var body: some View {
        HStack{
            Spacer()
            // Decorative bamboos yield their width to the label at accessibility sizes
            if !dynamicTypeSize.isAccessibilitySize {
                Image(quizModel.leftImage).resizable().scaledToFit().frame(maxHeight: height / 3).a11yDecorative()
                Spacer()
            }
            Text("Maceraya Atıl").scaledFont(size: 22, weight: .bold).foregroundStyle(.brown300).multilineTextAlignment(.center)
                // Grow vertically only at accessibility sizes; default layout stays untouched
                .fixedSize(horizontal: false, vertical: dynamicTypeSize.isAccessibilitySize)
            Spacer()
            if !dynamicTypeSize.isAccessibilitySize {
                Image(quizModel.rightImage).resizable().scaledToFit().frame(maxHeight: height / 3).a11yDecorative()
                Spacer()
            }
        }.padding()
        .padding(.vertical)
        .background(.backgroundSystem)
        .borderRadius(borderColor: .unselectedButton)
        .onTapGesture {
            onClick(quizModel.quizType)
        }
        .a11yTapButton()
        .frame(width: height * 8 / 9)
    }
}

#Preview {
    QuizRowUI(quizModel: QuizRowModel(leftImage: "bambuuLeft", rightImage: "bambuuRight", quizType: .flashCard), height: 400, onClick: ({ _ in }))
}

