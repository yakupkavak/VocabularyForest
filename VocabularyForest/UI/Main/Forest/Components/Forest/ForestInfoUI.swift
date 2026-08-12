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
        static let rainIconWidth: CGFloat = 44
        /// Every row reserves the widest icon's width so the texts stay aligned.
        static let iconSlotWidth: CGFloat = 44
        static let titleFontSize: CGFloat = 15
        static let detailFontSize: CGFloat = 12
        static let horizontalPadding: CGFloat = 2
        static let minimumScaleFactor: CGFloat = 0.8
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
            GamePopUpContainer(title: String(localized: "Doğa Dengesi"), onClose: onClose, screenWidth: geometry.size.width) {
                VStack(spacing: Constants.rowSpacing) {
                    if let forestModel {
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
                            Image("gold_icon").resizable().scaledToFit().frame(width: Constants.iconWidth)
                        }
                        infoRow(
                            title: "Elmas: \(forestModel.diamond)",
                            detail: "Nadir bulunur, özel eşyalar için harcayabilirsin."
                        ) {
                            Image("diamond_icon").resizable().scaledToFit().frame(width: Constants.iconWidth)
                        }
                        infoRow(
                            title: "Toprak sağlığı: %\(forestModel.landHealthPercentage)",
                            detail: "Mutlu hayvan ve bitkiler için olmazsa olmaz."
                        ) {
                            Image(systemName: "leaf.fill").resizable().scaledToFit().frame(width: Constants.iconWidth).foregroundStyle(.logoGreen)
                        }
                    } else {
                        Text("Beklenmedik hata").foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - UI COMPONENTS

private extension ForestInfoUI {

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
        Image(systemName: "drop").resizable().scaledToFit().frame(width: Constants.rainIconWidth).foregroundStyle(.brown700).overlay {
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
