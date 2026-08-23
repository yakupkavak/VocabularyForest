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
        static let talkingBoxSpacing: CGFloat = 16
        static let talkingBoxPadding: CGFloat = 24
        static let talkingBoxFontSize: CGFloat = 20
        static let talkingBoxMaxWidthRatio: CGFloat = 0.6
    }
}

struct BaseOnboardingUI: View {
    //MARK: Properties
    @State private var showText = false
    @State private var showBallon = false
    var onboardingModel: OnboardingModel

    var body: some View {
        VStack{
            if let animal = onboardingModel.animal, let backgroundImage = onboardingModel.backgroundImage {
                // Title is optional: a page with a nil title shows only its background;
                // the whole talking box (text + bubbles) is skipped.
                animalTalking(animal: animal, title: onboardingModel.title, color: onboardingModel.color, backgroundImageName: backgroundImage).ignoresSafeArea(.all)
            }
        }.ignoresSafeArea(.all)
    }
}

// MARK: - VIEW COMPONENTS

private extension BaseOnboardingUI {
    @ViewBuilder
    func animalTalking(animal: String, title: String?, color: Color, backgroundImageName: String? = nil) -> some View {
        ZStack {
            if let image = backgroundImageName {
                Image(image).resizable().scaledToFill().frame(minHeight: 0, maxHeight: .infinity).a11yDecorative()
            }
            GeometryReader { proxy in
                VStack(alignment: .center){
                    if let title {
                        talkingBox(
                            message: title,
                            maxWidth: proxy.size.width * Constants.talkingBoxMaxWidthRatio
                        )
                    }
                    if backgroundImageName == nil {
                        Image(animal).resizable().frame(maxWidth:96, maxHeight: 96).scaledToFit().a11yDecorative()
                    }
                }
                .position(
                    x: proxy.size.width / 2,
                    y: proxy.size.height * onboardingModel.talkingBoxCenterRatio
                )
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
    func talkingBox(message: String, maxWidth: CGFloat) -> some View {
        VStack(spacing: Constants.talkingBoxSpacing){
            if showText {
                Text(message).foregroundStyle(.white).scaledFont(size: Constants.talkingBoxFontSize).padding(Constants.talkingBoxPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.talkingBoxCornerRadius)
                            .fill(.title)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: Constants.talkingBoxCornerRadius)
                            .strokeBorder(.white, lineWidth: Constants.talkingBoxBorderWidth)
                    }
                    // Capping outside the background lets the box hug short messages instead of
                    // padding out to the full allowance.
                    .frame(maxWidth: maxWidth)
            }
            if showBallon {
                TalkingBallons().a11yDecorative()
            }
        }
    }
}



#Preview {
    BaseOnboardingUI(onboardingModel: OnboardingModel(title: "Burası da neresi", animal: "elephant", color: Color.accentColor, backgroundImage: "elephantbackground"))
}
