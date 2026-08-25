//
//  ForestInfoUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.12.2025.
//

import SwiftUI

// MARK: - CONSTANTS

private extension ForestInfoUI {
    enum Constants {
        static let rowSpacing: CGFloat = 24
        static let iconWidth: CGFloat = 32
        static let iconHeight: CGFloat = 32
        static let rainIconWidth: CGFloat = 44
        static let rainIconHeight: CGFloat = 44
        /// The diamond artwork is a flat rhombus, so at the shared icon width it reads far
        /// lighter than the round coin; a slightly larger box evens the two out.
        static let diamondIconWidth: CGFloat = 40
        static let diamondIconHeight: CGFloat = 40
        /// Every row reserves the widest icon's width so the texts stay aligned.
        static let iconSlotWidth: CGFloat = 44
        static let titleFontSize: CGFloat = 15
        static let detailFontSize: CGFloat = 12
        static let horizontalPadding: CGFloat = 2
        static let minimumScaleFactor: CGFloat = 0.8
        /// Dynamic Type can push the rows past the screen; the popup stops growing here and
        /// scrolls instead of covering everything.
        static let popUpHeightRatio: CGFloat = 0.7
        /// GamePopUpContainer caps the popup at this share of the screen and pads it by this much.
        /// The rows are pinned to the resulting content width so SwiftUI measures their *wrapped*
        /// height: the container is horizontally fixedSize, so it otherwise measures the rows at
        /// their unwrapped one-line width and then hands them far less height than they need —
        /// which is what used to squeeze the icons down to nothing.
        static let popUpWidthRatio: CGFloat = 0.7
        static let popUpHorizontalPadding: CGFloat = 24
    }
}

// MARK: - VIEW

struct ForestInfoUI: View {

    // MARK: - PROPERTIES

    var forestModel: ForestStatusModel?
    var onClose: () -> Void

    // MARK: - BODY

    var body: some View {
        GeometryReader { geometry in
            let maxPopUpHeight = geometry.size.height * Constants.popUpHeightRatio
            // Below the cap the popup hugs its rows; past it the height freezes and the rows
            // scroll inside, so the largest Dynamic Type sizes stay reachable.
            ViewThatFits(in: .vertical) {
                popUp(screenWidth: geometry.size.width) {
                    content(screenWidth: geometry.size.width)
                }
                popUp(screenWidth: geometry.size.width) {
                    ScrollView(showsIndicators: false) {
                        content(screenWidth: geometry.size.width)
                    }
                }
                .frame(height: maxPopUpHeight)
            }
            .frame(maxHeight: maxPopUpHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - UI COMPONENTS

private extension ForestInfoUI {

    func popUp<Content: View>(screenWidth: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        GamePopUpContainer(title: String(localized: "Doğa Dengesi"), onClose: onClose, screenWidth: screenWidth) {
            content()
        }
    }

    @ViewBuilder
    func content(screenWidth: CGFloat) -> some View {
        if let forestModel {
            rows(forestModel, screenWidth: screenWidth)
        } else {
            // The status is refreshed on demand when the popup opens; a nil model
            // only means the fetch is still in flight, not an error.
            ProgressView().tint(.white)
        }
    }

    func rows(_ forestModel: ForestStatusModel, screenWidth: CGFloat) -> some View {
        VStack(spacing: Constants.rowSpacing) {
            infoRow(
                title: "Doluluk oranı \(forestModel.rainValue) / \(ForestConstant.rainCostValue)",
                detail: "Ormanına can vermek için doldurmalısın."
            ) {
                rainIcon(filledRatio: CGFloat(forestModel.rainValue) / CGFloat(ForestConstant.rainCostValue))
            }
            infoRow(
                title: "Altın: \(forestModel.gold)",
                detail: "Gelecek güncelleme ile mağazada kullanabileceksin."
            ) {
                Image("gold_icon").resizable().scaledToFit().frame(width: Constants.iconWidth, height: Constants.iconHeight).a11yDecorative()
            }
            infoRow(
                title: "Elmas: \(forestModel.diamond)",
                detail: "Nadir bulunur, özel eşyalar için harcayabilirsin."
            ) {
                Image("diamond_icon").resizable().scaledToFit().frame(width: Constants.diamondIconWidth, height: Constants.diamondIconHeight).a11yDecorative()
            }
            infoRow(
                title: "Toprak sağlığı: %\(forestModel.landHealthPercentage)",
                detail: "Mutlu hayvan ve bitkiler için olmazsa olmaz."
            ) {
                Image(systemName: "leaf.fill").resizable().scaledToFit().frame(width: Constants.iconWidth, height: Constants.iconHeight).foregroundStyle(.logoGreen)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(width: screenWidth * Constants.popUpWidthRatio - Constants.popUpHorizontalPadding * 2)
    }

    func infoRow<Icon: View>(title: LocalizedStringKey, detail: LocalizedStringKey, @ViewBuilder icon: () -> Icon) -> some View {
        HStack {
            icon().frame(width: Constants.iconSlotWidth)
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(.white)
                    .scaledFont(size: Constants.titleFontSize)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(Constants.minimumScaleFactor)
                Text(detail)
                    .foregroundStyle(.white)
                    .scaledFont(size: Constants.detailFontSize)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    /// Outlined drop whose fill height mirrors how full the rain tank is.
    func rainIcon(filledRatio: CGFloat) -> some View {
        // Fix both dimensions: with only a width the icon collapses when the row proposes a short height.
        Image(systemName: "drop").resizable().scaledToFit().frame(width: Constants.rainIconWidth, height: Constants.rainIconHeight).foregroundStyle(.brown700).overlay {
            Image(systemName: "drop.fill").resizable().scaledToFit().foregroundStyle(.brown700).mask {
                GeometryReader { geo in
                    Rectangle().frame(height: geo.size.height * filledRatio)
                }
            }
        }
    }
}

#Preview {
    ForestInfoUI(forestModel: ForestStatusModel(rainValue: 10, landHealthPercentage: 10, landStatus: true, gold: 210, diamond: 42), onClose: { })
}
