//
//  FlashCardComponents.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.11.2025.
//

import SwiftUI
import Combine

struct FlashCardFront : View {
    
    // MARK: - PROPERTIES

    @Binding var degree: Double
    let book: Book
    let type: FlashCardQuestionType
    let width: CGFloat = 300
    let height: CGFloat = 450

    // MARK: - VIEW

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#022601"))
                .frame(width: width, height: height)
                .shadow(color: .gray, radius: 2, x: 0, y: 0)
            
            VStack(spacing: 20) {
                Text(questionTitle)
                    .font(.headline)
                    .foregroundColor(Color(hex:"#F2CB05").opacity(0.7))
                
                Text(questionText)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex:"#F2CB05")) 
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: width * 0.9)
            }
            .padding(20)
        }
        .rotation3DEffect(Angle(degrees: degree), axis: (x: 0, y: 1, z: 0))
    }
    
    var questionTitle: String {
        switch type {
        case .definition: return "Bu kelimenin İngilizcesi nedir?"
        case .fillInTheBlank: return "Boşluğu doldurun:"
        case .description: return "Bu hangi kelimenin açıklaması?"
        }
    }
    
    var questionText: String {
        switch type {
        case .definition:
            return book.unwrappedMeaningWord
        case .fillInTheBlank:
            return createBlankSentence(
                from: book.exampleSentence ?? "",
                replacing: book.unwrappedLearningWord
            )
        case .description:
            return book.descriptionWord ?? "Açıklama yok"
        }
    }
    
    func createBlankSentence(from sentence: String, replacing word: String) -> String {
        if sentence.isEmpty { return "(Örnek cümle yok)" }
        return sentence.replacingOccurrences(
            of: word,
            with: "_______",
            options: .caseInsensitive
        )
    }
}

struct FlashCardBack : View {
    
    // MARK: - PROPERTIES
    
    @Binding var degree: Double
    let learningWord: String
    let meaningWord: String
    let width: CGFloat = 300
    let height: CGFloat = 450
    
    // MARK: - VIEW

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#F2EEAE").opacity(0.9))
                .frame(width: width, height: height)
                .shadow(color: .gray, radius: 2, x: 0, y: 0)

            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex:"#022601").opacity(0.7), lineWidth: 3)
                .frame(width: width, height: height)
            
            VStack(spacing: 10){
                Text(learningWord)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#022601"))
                    .frame(maxWidth: width * 0.9)

                Text(meaningWord)
                    .font(.title2)
                    .foregroundColor(Color(hex: "#8C3027"))
                    .frame(maxWidth: width * 0.9)
            }
            .padding()

        }
        .rotation3DEffect(Angle(degrees: degree), axis: (x: 0, y: 1, z: 0))
    }
}
