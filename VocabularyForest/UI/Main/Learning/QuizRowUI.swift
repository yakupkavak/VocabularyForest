//
//  QuizRowUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//

import SwiftUI

struct QuizRowUI: View {
    
    // MARK: - PROPERTIES
    
    var quizType: QuizType
    var imageLeftName: String
    var imageRightName: String
    var onClick: (QuizType) -> Void
    
    // MARK: - UI
    
    var body: some View {
        HStack{
            Image(imageLeftName).resizable().scaledToFit().frame(maxWidth: 40)
            VStack{
                Text("Flash Card").font(.system(size: 20, weight: .bold)).foregroundStyle(.brown300)
                Text("Boost your knowledge").font(.system(size: 14, weight: .regular)).foregroundStyle(.gray.opacity(0.9))
            }
            Image(imageRightName).resizable().scaledToFit().frame(maxWidth: 40)
        }.padding()
            .padding(.vertical)
        .background(.backgroundSystem)
        .borderRadius(borderColor: .unselectedButton)
        .onTapGesture {
            onClick(quizType)
        }
    }
}

enum QuizType{
    case flashCard
}

#Preview {
    QuizRowUI(quizType: .flashCard, imageLeftName: "bambuuLeft", imageRightName: "bambuuRight"){ type in
        switch type {
        case .flashCard:
            print("flashcard clicked")
        }
    }
}
