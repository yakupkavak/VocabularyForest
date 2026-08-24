//
//  ContinueGamePopUp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.07.2026.
//

import SwiftUI
import Combine

// MARK: - CONSTANTS

private extension ContinueGamePopUp {
    enum Constants {
        static let countdownSeconds: Int = 5
        static let iconSize: CGFloat = 36
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 4
        static let contentPadding: CGFloat = 24
        static let contentSpacing: CGFloat = 20
        static let overlayOffset: CGFloat = 12
        static let widthRatio: CGFloat = 0.8
        static let countdownFontSize: CGFloat = 48
        static let descriptionFontSize: CGFloat = 14
        static let popUpZIndex: Double = 4.0
        static let openSoundName: String = "popup_open_sound"
        static let tickSoundName: String = "tick_sound"
        static let closeSoundName: String = "popup_close_sound"
    }
}

// MARK: - VIEW

struct ContinueGamePopUp: View {

    // MARK: - PROPERTIES
    
    var titleText: String
    var descriptionText: String?
    var diamondCost: Int
    var audioService: AudioServiceProtocol
    var onConfirm: () -> Void
    var onDiamondContinue: () -> Void
    var onClose: () -> Void
    var confirmText: String

    @State private var remainingSeconds: Int = Constants.countdownSeconds
    @State private var animalHead = getRandomAnimalModel().head
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Constants.contentSpacing) {
            Text(titleText)
                .foregroundStyle(.title)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .fontWeight(.bold)
            countdownView
            if let descriptionText {
                Text(descriptionText)
                    .foregroundStyle(.forestText)
                    .scaledFont(size: Constants.descriptionFontSize)
                    .multilineTextAlignment(.leading)
            }
            HStack {
                diamondButton
                watchAdButton
            }
        }
        .padding(Constants.contentPadding)
        .background(Color.backgroundSystem)
        .cornerRadius(Constants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .strokeBorder(Color("brown300"), lineWidth: Constants.borderWidth)
        )
        .overlay(alignment: .topTrailing) {
            if isCloseAvailable {
                closeButton
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * Constants.widthRatio)
        .overlay(alignment: .topLeading) {
            Image(animalHead)
                .resizable()
                .frame(maxWidth: Constants.iconSize, maxHeight: Constants.iconSize)
                .offset(x: Constants.overlayOffset, y: -Constants.overlayOffset)
        }
        .zIndex(Constants.popUpZIndex)
        .onAppear {
            audioService.playSFX(filename: Constants.openSoundName)
        }
        .onReceive(timer) { _ in
            handleTick()
        }
    }

}

// MARK: - UI COMPONENTS

private extension ContinueGamePopUp {

    @ViewBuilder
    var countdownView: some View {
        if !isCloseAvailable {
            Text("\(remainingSeconds)")
                .scaledFont(size: Constants.countdownFontSize)
                .fontWeight(.heavy)
                .monospacedDigit()
                .foregroundStyle(.errorBorder)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityLabel(
                    String(format: NSLocalizedString("a11y_continue_countdown", comment: ""), remainingSeconds)
                )
        }
    }

    var watchAdButton: some View {
        Button {
            onConfirm()
            onClose()
        } label: {
            HStack {
                Image("watch_icon")
                    .resizable()
                    .a11yDecorative()
                    .frame(maxWidth: Constants.iconSize, maxHeight: Constants.iconSize)
                Spacer()
                Text(confirmText)
                Spacer()
            }.modifier(ForestButtonBackground(color: .logoGreen))
        }
    }

    var diamondButton: some View {
        Button {
            onDiamondContinue()
            onClose()
        } label: {
            HStack {
                Image("diamond_icon")
                    .resizable()
                    .scaledToFit()
                    .a11yDecorative()
                    .frame(maxWidth: Constants.iconSize, maxHeight: Constants.iconSize)
                Text("\(diamondCost)")
            }.modifier(ForestButtonBackground(color: .clickableButton))
        }
    }

    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image("close_button")
                .resizable()
                .frame(maxWidth: Constants.iconSize, maxHeight: Constants.iconSize)
                .offset(x: Constants.overlayOffset, y: -Constants.overlayOffset)
                .accessibilityLabel(String(localized: "a11y_close"))
        }
    }

}

// MARK: - HELPERS

private extension ContinueGamePopUp {

    var isCloseAvailable: Bool {
        remainingSeconds == 0
    }

    func handleTick() {
        guard remainingSeconds > 0 else { return }
        withAnimation {
            remainingSeconds -= 1
        }
        audioService.playSFX(filename: Constants.tickSoundName)
    }

    // Only the explicit dismiss plays the close sound; the confirm paths hand off to
    // an ad or straight back to the game, where a rustle on top of that just muddies it.
    func dismiss() {
        audioService.playSFX(filename: Constants.closeSoundName)
        onClose()
    }

}

#Preview {
    ContinueGamePopUp(
        titleText: "Continue your journey",
        descriptionText: "You can continue your game within?",
        diamondCost: 15,
        audioService: ForestAudioService(),
        onConfirm: { },
        onDiamondContinue: { },
        onClose: { },
        confirmText: "Watch the Video"
    )
}
