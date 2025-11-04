//
//  LearningFeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI

struct LearningFeedUI: View {
    var body: some View {
        ZStack{
            Color.backgroundSystem.ignoresSafeArea()
            VStack{
                tvMainTitle(text: "Todays Card")
                TodayCardUI()
            }
        }
    }
}

private extension LearningFeedUI {
    enum Constant {
        static let quizList = [QuizRowModel(
            leftImage: "bambuuLeft",
            rightImage: "bambuuRight",
            quizType: .flashCard
        ),]
    }
}

#Preview {
    LearningFeedUI()
}
