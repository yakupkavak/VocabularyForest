//
//  BaseOnboardingUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

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
                Image(image).resizable().scaledToFill().frame(minHeight: 0, maxHeight: .infinity)
            }
            VStack(alignment: .center){
                Spacer()
                talkingBox(message: title).offset(y: -120)
                if backgroundImageName == nil {
                    Image(animal).resizable().frame(maxWidth:96, maxHeight: 96).scaledToFit()
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
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white, lineWidth: 4)
                    }
            }
            if showBallon {
                TalkingBallons()
            }
        }
    }
}



#Preview {
    BaseOnboardingUI(onboardingModel: OnboardingModel(title: "Uzun zamandır sana ihtiyacımız vardı", animal: "elephant", color: Color.accentColor, backgroundImage: "elephantbackground"))
}
