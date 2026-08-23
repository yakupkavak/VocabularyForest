//
//  GameInfoUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.12.2025.
//

import SwiftUI

struct GameInfoModel {
    let title: String
    let image: String
    let description: String
}

let gameInfoText: [GameInfoModel] = [
    GameInfoModel(title: String(localized: "Orman Hakkında"), image: "foresttanitim0",description: String(localized: "Ormanına hoşgeldin! Görevleri tamamlayarak ormanına hayat katabilirsin. Toprağın zamanla kuruyacaktır, bunun için yağmur yağdırmayı unutma!")),
    GameInfoModel(title: String(localized: "Sorular Hakkında"), image: "foresttanitim3",description: String(localized: "Kelimelerin kısa ve uzun hafıza olarak ikiye ayrılmış durumda. Bir kelimeyi rekabet modunda bildiğinde uzun hafızana geçiyor. Ama unutma, bir hafta içerisinde hatırlatıcı modu ile tekrarlamazsan kısa hafızana geçecek!")),
    GameInfoModel(title: String(localized: "Yağmur Hakkında"), image: "foresttanitim1",description: String(localized: "Görevleri tamamlayarak yağmur taneleri toplayıp, hazneni doldurduğunda ekranında belirecek butona tıklayarak yağmur yağdırabilirsin.")),
    GameInfoModel(title: String(localized: "Canlılar Hakkında"),image: "foresttanitim0",description: String(localized: "Bitkilerin sağlıksız bir toprakta kuruyacaktır, hayvanların ise hareket edemeyecekler.."))
]

// MARK: - CONSTANTS

private extension GameInfoUI {
    enum Constants {
        static let contentSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 12
        static let cardWidthRatio: CGFloat = 0.8
        static let outerWidthRatio: CGFloat = 0.85
        static let maxCardWidth: CGFloat = 400
        static let imageWidthRatio: CGFloat = 0.75
        static let imageHeight: CGFloat = 150
        static let imageCornerRadius: CGFloat = 20
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 4
        static let backgroundOpacity: Double = 0.95
        static let descriptionFontSize: CGFloat = 13
        static let closeButtonSize: CGFloat = 36
        static let closeButtonOffset: CGFloat = 12
        static let indicatorTintOpacity: CGFloat = 0.3
        static let overlayZIndex: Double = 4.0
        /// Band the `.page` style draws its dots in, reserved by the page itself
        /// so the description never runs underneath them.
        static let pageIndicatorReserve: CGFloat = 40
        /// The card grows with the text up to this share of the screen; past it
        /// the description scrolls instead of pushing the card off screen.
        static let maxCardHeightRatio: CGFloat = 0.75
    }
}

// MARK: - VIEW

struct GameInfoUI: View {

    // MARK: - PROPERTIES

    @Binding var showForestPopUp: Bool
    @State private var currentPage = 0
    @State private var measuredPageHeight: CGFloat = 0

    // MARK: - BODY

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(gameInfoText.indices, id: \.self) { index in
                page(gameInfoText[index], isMeasuring: false).tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: cardContentHeight)
        .padding(Constants.cardPadding)
        .background(Color.brown.opacity(Constants.backgroundOpacity))
        .frame(maxWidth: cardWidth)
        .cornerRadius(Constants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .strokeBorder(Color("brown300"), lineWidth: Constants.borderWidth)
        )
        .overlay(alignment: .topTrailing) { closeButton }
        .background(pageMeasurement)
        .frame(maxWidth: UIScreen.main.bounds.width * Constants.outerWidthRatio)
        .zIndex(Constants.overlayZIndex)
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = .white
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(Constants.indicatorTintOpacity)
        }
    }
}

// MARK: - UI COMPONENTS

private extension GameInfoUI {

    /// One info page. While measuring, the artwork becomes a same-height spacer
    /// and the description loses its scroll view, so the copy reports the height
    /// the page actually wants instead of the height it was handed.
    @ViewBuilder
    func page(_ model: GameInfoModel, isMeasuring: Bool) -> some View {
        VStack(spacing: Constants.contentSpacing) {
            Text(LocalizedStringKey(model.title))
                .fixedSize(horizontal: false, vertical: true)
                .modifier(TitleBackground())
                .padding()

            if isMeasuring {
                Color.clear.frame(height: Constants.imageHeight)
            } else {
                Image(model.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: imageWidth, minHeight: Constants.imageHeight, maxHeight: Constants.imageHeight)
                    .cornerRadius(Constants.imageCornerRadius)
            }

            if isMeasuring {
                description(model)
            } else {
                // Only scrolls once the card has hit its height cap — below the cap
                // the card already grew to fit, so there is nothing left to scroll.
                ScrollView(showsIndicators: false) {
                    description(model)
                }
            }
        }
        .padding(.bottom, Constants.pageIndicatorReserve)
    }

    func description(_ model: GameInfoModel) -> some View {
        Text(LocalizedStringKey(model.description))
            .foregroundStyle(.white)
            .scaledFont(size: Constants.descriptionFontSize, weight: .medium)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Off-screen copy of every page at its natural height. The tallest one sizes
    /// the card, so short pages stop reserving the empty space a fixed-height
    /// TabView used to claim; the card only grows when Dynamic Type does.
    var pageMeasurement: some View {
        ZStack {
            ForEach(gameInfoText.indices, id: \.self) { index in
                page(gameInfoText[index], isMeasuring: true)
                    .frame(width: contentWidth)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: GameInfoPageHeightKey.self, value: proxy.size.height)
                        }
                    )
            }
        }
        .hidden()
        .accessibilityHidden(true)
        .onPreferenceChange(GameInfoPageHeightKey.self) { measuredPageHeight = $0 }
    }

    var closeButton: some View {
        Button {
            showForestPopUp = false
        } label: {
            Image("close_button")
                .resizable()
                .frame(maxWidth: Constants.closeButtonSize, maxHeight: Constants.closeButtonSize)
                .offset(x: Constants.closeButtonOffset, y: -Constants.closeButtonOffset)
                .accessibilityLabel(String(localized: "a11y_close"))
        }
    }
}

// MARK: - HELPERS

private extension GameInfoUI {

    var cardWidth: CGFloat {
        min(UIScreen.main.bounds.width * Constants.cardWidthRatio, Constants.maxCardWidth)
    }

    var contentWidth: CGFloat {
        cardWidth - Constants.cardPadding * 2
    }

    var imageWidth: CGFloat {
        min(UIScreen.main.bounds.width * Constants.imageWidthRatio, Constants.maxCardWidth)
    }

    var cardContentHeight: CGFloat {
        let cap = UIScreen.main.bounds.height * Constants.maxCardHeightRatio - Constants.cardPadding * 2
        // Falling back to the cap keeps the first frame full-size rather than
        // collapsed while the measurement pass is still pending.
        guard measuredPageHeight > 0 else { return cap }
        return min(measuredPageHeight, cap)
    }
}

/// Tallest page across the pager, so the card can hug its content.
private enum GameInfoPageHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ZStack {
        Color.green.ignoresSafeArea()
        GameInfoUI(showForestPopUp: .constant(true))
    }
}
