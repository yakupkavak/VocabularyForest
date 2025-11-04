//
//  LearningFeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI

struct LearningFeedUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject var viewModel = LearningFeedViewModel()
    
    // MARK: - VIEW
    
    var body: some View {
        ZStack{
            Color.backgroundSystem.ignoresSafeArea()
            VStack{
                Spacer()
                tvMainTitle(text: "Learning").padding(.bottom)
                ForEach(Constant.quizList, id: \.self) { quiz in
                    QuizRowUI(quizModel: quiz) { type in
                        switch type {
                        case .flashCard:
                            print("flash card")
                        }
                    }.listRowInsets(.init())
                        .listRowSeparator(.hidden, edges: .all)
                }
                Spacer()
                tvMainTitle(text: "Todays Card")
                TodayCardUI(
                    learningWord: viewModel.todaysLearningWord,
                    meaningWord: viewModel.todaysMeaning,
                    exampleSentence: viewModel.todaysExample,
                    descriptionSentence: viewModel.todaysDescription
                )
                Spacer()
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
