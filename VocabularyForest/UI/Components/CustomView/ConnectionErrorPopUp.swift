//
//  ConnectionErrorPopUp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.08.2026.
//

import SwiftUI
import Combine

// MARK: - CONSTANTS

private extension ConnectionErrorPopUp {
    enum Constants {
        static let iconSize: CGFloat = 36
        static let statusIconSize: CGFloat = 56
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 4
        static let contentPadding: CGFloat = 24
        static let contentSpacing: CGFloat = 20
        static let overlayOffset: CGFloat = 12
        static let widthRatio: CGFloat = 0.8
        static let descriptionFontSize: CGFloat = 14
        static let popUpZIndex: Double = 4.0
        static let disabledButtonOpacity: Double = 0.5
        static let statusIconName: String = "wifi.slash"
        static let openSoundName: String = "popup_open_sound"
        static let closeSoundName: String = "popup_close_sound"
    }
}

// MARK: - VIEW

struct ConnectionErrorPopUp: View {

    // MARK: - PROPERTIES

    var cooldownSeconds: Int
    var audioService: AudioServiceProtocol
    var onRetry: () -> Void
    var onClose: () -> Void

    @State private var remainingSeconds: Int = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Constants.contentSpacing) {
            Text(String(localized: "connection_error_title"))
                .foregroundStyle(.title)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .fontWeight(.bold)
            Image(systemName: Constants.statusIconName)
                .resizable()
                .scaledToFit()
                .a11yDecorative()
                .frame(maxWidth: Constants.statusIconSize, maxHeight: Constants.statusIconSize)
                .foregroundStyle(.errorBorder)
            Text(String(localized: "connection_error_description"))
                .foregroundStyle(.forestText)
                .scaledFont(size: Constants.descriptionFontSize)
                .multilineTextAlignment(.leading)
            retryButton
        }
        .padding(Constants.contentPadding)
        .background(Color.backgroundSystem)
        .cornerRadius(Constants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .strokeBorder(Color("brown300"), lineWidth: Constants.borderWidth)
        )
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .frame(maxWidth: UIScreen.main.bounds.width * Constants.widthRatio)
        .zIndex(Constants.popUpZIndex)
        .onAppear {
            remainingSeconds = cooldownSeconds
            audioService.playSFX(filename: Constants.openSoundName)
        }
        .onReceive(timer) { _ in
            handleTick()
        }
    }

}

// MARK: - UI COMPONENTS

private extension ConnectionErrorPopUp {

    var retryButton: some View {
        Button {
            onRetry()
        } label: {
            HStack {
                Spacer()
                Text(retryButtonText)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                Spacer()
            }.modifier(ForestButtonBackground(color: .logoGreen))
        }
        .disabled(!isRetryAvailable)
        .opacity(isRetryAvailable ? 1 : Constants.disabledButtonOpacity)
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

private extension ConnectionErrorPopUp {

    var isRetryAvailable: Bool {
        remainingSeconds == 0
    }

    var retryButtonText: String {
        if isRetryAvailable {
            return String(localized: "connection_error_retry")
        }
        return String(
            format: NSLocalizedString("connection_error_retry_countdown", comment: ""),
            remainingSeconds
        )
    }

    func handleTick() {
        guard remainingSeconds > 0 else { return }
        withAnimation {
            remainingSeconds -= 1
        }
    }

    func dismiss() {
        audioService.playSFX(filename: Constants.closeSoundName)
        onClose()
    }

}

#Preview {
    ConnectionErrorPopUp(
        cooldownSeconds: 5,
        audioService: ForestAudioService(),
        onRetry: { },
        onClose: { }
    )
}
