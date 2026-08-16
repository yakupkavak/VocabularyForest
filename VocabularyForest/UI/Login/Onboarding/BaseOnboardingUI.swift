//
//  BaseOnboardingUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

// MARK: - CONSTANTS

private extension BaseOnboardingUI {
    enum Constants {
        static let talkingBoxCornerRadius: CGFloat = 16
        static let talkingBoxBorderWidth: CGFloat = 4
        static let talkingBoxYOffset: CGFloat = -144
    }
}

struct BaseOnboardingUI: View {
    //MARK: Properties
    @State private var showText = false
    @State private var showBallon = false
    var onboardingModel: OnboardingModel

    var body: some View {
        VStack{
            if let title = onboardingModel.title, let animal = onboardingModel.animal, let backgroundImage = onboardingModel.backgroundImage {
                animalTalking(animal: animal, title: title, color: onboardingModel.color, backgroundImageName: backgroundImage).ignoresSafeArea(.all)
            }
        }.ignoresSafeArea(.all)
    }
}

// MARK: - VIEW COMPONENTS

private extension BaseOnboardingUI {
    @ViewBuilder
    func animalTalking(animal: String, title: String, color: Color, backgroundImageName: String? = nil) -> some View {
        ZStack {
            if let image = backgroundImageName {
                Image(image).resizable().scaledToFill().frame(minHeight: 0, maxHeight: .infinity).a11yDecorative()
            }
            VStack(alignment: .center){
                Spacer()
                talkingBox(message: title).offset(y: Constants.talkingBoxYOffset)
                if backgroundImageName == nil {
                    Image(animal).resizable().frame(maxWidth:96, maxHeight: 96).scaledToFit().a11yDecorative()
                }
                Spacer()
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(.clear)
        }.ignoresSafeArea(.all).frame(minWidth: 0, maxWidth: .infinity)
            .onAppear {
                withAnimation(Animation.spring().delay(0.5)) {
                         self.showBallon = true
                    }
                withAnimation(Animation.spring(duration: 0.5).delay(1.15)) {
                         self.showText = true
                    }
            }
    }
    
    @ViewBuilder
    func talkingBox(message: String) -> some View {
        VStack(spacing: 16){
            if showText {
                Text(message).foregroundStyle(.white).scaledFont(size: 20).frame(maxWidth: 250).padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.talkingBoxCornerRadius)
                            .fill(.title)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: Constants.talkingBoxCornerRadius)
                            .strokeBorder(.title, lineWidth: Constants.talkingBoxBorderWidth)
                    }
            }
            if showBallon {
                TalkingBallons(foregroundColor: .title).a11yDecorative()
            }
        }
    }
}



#Preview {
    BaseOnboardingUI(onboardingModel: OnboardingModel(title: "Uzun zamandır sana ihtiyacımız vardı", animal: "elephant", color: Color.accentColor, backgroundImage: "elephantbackground"))
}
