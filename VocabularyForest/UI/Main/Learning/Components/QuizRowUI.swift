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

    // MARK: - UI
    
    var body: some View {
        HStack{
            Spacer()
            Image(quizModel.leftImage).resizable().scaledToFit().frame(maxHeight: height / 3)
            Spacer()
            Text("Maceraya Atıl").font(.system(size: 22, weight: .bold)).foregroundStyle(.brown300).multilineTextAlignment(.center)
            Spacer()
            Image(quizModel.rightImage).resizable().scaledToFit().frame(maxHeight: height / 3)
            Spacer()
        }.padding()
        .padding(.vertical)
        .background(.backgroundSystem)
        .borderRadius(borderColor: .unselectedButton)
        .onTapGesture {
            onClick(quizModel.quizType)
        }
        .frame(width: height * 8 / 9)
    }
}

#Preview {
    QuizRowUI(quizModel: QuizRowModel(leftImage: "bambuuLeft", rightImage: "bambuuRight", quizType: .flashCard), height: 400, onClick: ({ _ in }))
}

