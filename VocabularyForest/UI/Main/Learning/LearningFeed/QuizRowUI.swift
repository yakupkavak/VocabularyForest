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
    var onClick: (QuizType) -> Void
    
    // MARK: - UI
    
    var body: some View {
        HStack{
            Image(quizModel.leftImage).resizable().scaledToFit().frame(maxWidth: 40)
            VStack{
                Text("Flash Card").font(.system(size: 20, weight: .bold)).foregroundStyle(.brown300)
                Text("Boost your knowledge").font(.system(size: 14, weight: .regular)).foregroundStyle(.gray.opacity(0.9))
            }
            Image(quizModel.rightImage).resizable().scaledToFit().frame(maxWidth: 40)
        }.padding()
            .padding(.vertical)
        .background(.backgroundSystem)
        .borderRadius(borderColor: .unselectedButton)
        .onTapGesture {
            onClick(quizModel.quizType)
        }
    }
}

#Preview {
    QuizRowUI(quizModel: QuizRowModel(leftImage: "bambuuLeft", rightImage: "bambuuRight", quizType: .flashCard)){ type in
        switch type {
        case .flashCard:
            print("flashcard clicked")
        }
    }
}
