//
//  LearningFeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI
import Combine

struct LearningFeedUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject var viewModel = LearningFeedViewModel()
    @EnvironmentObject var router: LearningRouter

    // MARK: - VIEW
    
    var body: some View {
        ZStack{
            Color.backgroundSystem.ignoresSafeArea()
            VStack{
                Spacer()
                tvMainTitle(text: "Ormanın").padding(.bottom)
                ForEach(Constant.quizList, id: \.self) { quiz in
                    QuizRowUI(quizModel: quiz, height: UIScreen.main.bounds.height * 0.4) { type in
                        switch type {
                        case .flashCard:
                            router.navigate(to: .forest)
                        case .forest:
                            router.navigate(to: .forest)
                        }
                    }.listRowInsets(.init())
                        .listRowSeparator(.hidden, edges: .all)
                }
                Spacer()
                tvMainTitle(text: "Günün kartı")
                TodayCardUI(
                    height: UIScreen.main.bounds.height * 0.3,
                    learningWord: viewModel.todaysLearningWord,
                    meaningWord: viewModel.todaysMeaning,
                    exampleSentence: viewModel.todaysExample,
                    descriptionSentence: viewModel.todaysDescription,
                    onRefreshClick: viewModel.forceFetchNewWord
                )
                Spacer()
            }
        }.task {
            viewModel.fetchDailyWord()
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
