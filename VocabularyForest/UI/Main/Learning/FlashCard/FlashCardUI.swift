//
//  FlashCardUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.11.2025.
//

import SwiftUI
import Lottie
import Combine

struct FlashCardUI: View {
    
    @StateObject private var viewModel: FlashCardViewModel
    @Binding var tabBar: BaseTabTypes
    
    init(viewModel: FlashCardViewModel = FlashCardViewModel(manager: .shared), tabBar: Binding<BaseTabTypes>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _tabBar = tabBar
    }

    // MARK: - BODY
    
    var body: some View {
        ZStack {
            Color.backgroundSystem.ignoresSafeArea()
            VStack(spacing: 30) {
                
                if viewModel.noWordsFound {
                    Spacer()
                    Text("Henüz hiç kelime eklememişsin.")
                        .font(.title)
                        .foregroundColor(.gray)
                    VStack {
                        LottieView(animation: .named("sleepPanda"))
                            .playing(loopMode: .playOnce).resizable()
                    }.frame(height: UIScreen.main.bounds.height / 2)
                    Button("Kelime Ekle") {
                        tabBar = .createBook
                    }.font(.system(size: 24, weight: .bold)).padding().background(Color.clickableText).cornerRadius(16).foregroundStyle(.white)
                    Spacer()
                } else if let book = viewModel.currentBook {
                    ZStack {
                        FlashCardBack(
                            degree: $viewModel.backDegree,
                            learningWord: book.unwrappedLearningWord,
                            meaningWord: book.unwrappedMeaningWord
                        )
                        FlashCardFront(
                            degree: $viewModel.frontDegree,
                            book: book,
                            type: viewModel.currentQuestionType
                        )
                    }
                    .onTapGesture {
                        viewModel.flipCard()
                    }
                    buttons
                } else {
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - COMPONENTS

extension FlashCardUI {
    var buttons: some View {
        HStack(spacing: 25) {
            Button {
                viewModel.markCard(remembered: false)
            } label: {
                HStack {
                    Text("Unuttum")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }.padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.clickableButton)
                    .cornerRadius(16)
            }
            
            Button {
                viewModel.markCard(remembered: true)
            } label: {
                HStack {
                    Text("Biliyorum")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }.padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.standartText)
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
}
#Preview {
    //FlashCardUI(viewModel: FlashCardViewModel(manager: .preview))
}
