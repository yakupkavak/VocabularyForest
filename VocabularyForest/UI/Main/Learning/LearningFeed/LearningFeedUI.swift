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
    
    @ObservedObject var viewModel: LearningFeedViewModel
    @EnvironmentObject var router: LearningRouter
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - VIEW

    var body: some View {
        ZStack{
            Color.backgroundSystem.ignoresSafeArea()
            // Accessibility text sizes overflow the fixed layout; let it scroll instead
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(showsIndicators: false) {
                    feedContent
                }
            } else {
                feedContent
            }
        }.task {
            viewModel.fetchDailyWord()
        }.trackScreen(.learningFeed)
    }

    // MARK: - UI COMPONENTS

    private var feedContent: some View {
        VStack{
            Spacer()
            Text("Your Forest").scaledFont(size: 28, weight: .bold).foregroundStyle(.brown300).padding(.bottom).a11yHeader()
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
            Text("Daily Card").scaledFont(size: 28, weight: .bold).foregroundStyle(.brown300).a11yHeader()
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
    LearningFeedUI(viewModel: LearningFeedViewModel(coreDataManager: CoreDataManager()))
}
