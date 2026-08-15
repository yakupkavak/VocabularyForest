//
//  ManagePermissionsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.08.2026.
//

import SwiftUI

// MARK: - CONSTANTS

private extension ManagePermissionsUI {
    enum Constants {
        static let cardSpacing: CGFloat = 20
        static let rowSpacing: CGFloat = 6
        static let cardPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 4
        static let badgeSize: CGFloat = 36
        static let badgeOffset: CGFloat = 12
        static let iconWidth: CGFloat = 50
        static let descriptionFontSize: CGFloat = 14
        /// Wider than the 0.7 used by the confirmation popups: this card carries toggles plus
        /// explanatory copy, which wraps into an unreadable column at 0.7 on a 4.7" screen.
        static let cardWidthRatio: CGFloat = 0.85
        static let zIndex: Double = 4.0
    }
}

// MARK: - VIEW

struct ManagePermissionsUI: View {

    // MARK: - PROPERTIES

    @Binding var isAnalyticsEnabled: Bool
    let trackingStatusDescription: String
    let onOpenSystemSettings: () -> Void
    /// nil when there is no signed-in account; the section is hidden entirely in that case.
    let onDeleteAccount: (() -> Void)?
    let onClose: () -> Void

    @State private var animalHead = getRandomAnimalModel().head

    var body: some View {
        // No ScrollView: it would take every point it is offered and stretch the card to full
        // height. The card hugs its content instead, like the other popups in the app.
        VStack(alignment: .leading, spacing: Constants.cardSpacing) {
            Text("İzinleri Yönet")
                .foregroundStyle(.title)
                .fontWeight(.bold)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            analyticsSection
            Divider()
            trackingSection
            if onDeleteAccount != nil {
                Divider()
                deleteAccountSection
            }
        }
        .padding(Constants.cardPadding)
        .background(Color.backgroundSystem)
        .cornerRadius(Constants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .strokeBorder(Color("brown300"), lineWidth: Constants.borderWidth)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                onClose()
            } label: {
                Image("close_button")
                    .resizable()
                    .frame(maxWidth: Constants.badgeSize, maxHeight: Constants.badgeSize)
                    .offset(x: Constants.badgeOffset, y: -Constants.badgeOffset)
                    .accessibilityLabel(String(localized: "a11y_close"))
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * Constants.cardWidthRatio)
        .overlay(alignment: .topLeading) {
            Image(animalHead)
                .resizable()
                .a11yDecorative()
                .frame(maxWidth: Constants.badgeSize, maxHeight: Constants.badgeSize)
                .offset(x: Constants.badgeOffset, y: -Constants.badgeOffset)
        }
        .zIndex(Constants.zIndex)
    }
}

// MARK: - UI COMPONENTS

private extension ManagePermissionsUI {

    var analyticsSection: some View {
        VStack(alignment: .leading, spacing: Constants.rowSpacing) {
            Toggle(isOn: $isAnalyticsEnabled) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.logoGreen).frame(width: Constants.iconWidth)
                    Text("Kullanım Verileri")
                }
            }
            .tint(.logoGreen)
            Text("Hangi özellikleri kullandığını anonim olarak ölçer ve uygulamayı geliştirmemize yardım eder. Kapatırsan hiçbir kullanım verisi gönderilmez.")
                .foregroundStyle(.forestText)
                .scaledFont(size: Constants.descriptionFontSize)
        }
    }

    var trackingSection: some View {
        VStack(alignment: .leading, spacing: Constants.rowSpacing) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.logoBrown).frame(width: Constants.iconWidth)
                Text("Kişiselleştirilmiş Reklamlar")
                Spacer()
                Text(trackingStatusDescription)
                    .foregroundStyle(.secondaryText)
                    .scaledFont(size: Constants.descriptionFontSize)
            }
            Text("Reklamların ilgi alanlarına göre seçilmesi için kullanılır. Kapalıyken reklamları yine görürsün ama kişiselleştirilmez. Bu izin yalnızca sistem ayarlarından değiştirilebilir.")
                .foregroundStyle(.forestText)
                .scaledFont(size: Constants.descriptionFontSize)
            Button {
                onOpenSystemSettings()
            } label: {
                // Same tint as the selected bookcase header on the add-word screen.
                Text("Sistem Ayarlarını Aç")
                    .foregroundStyle(.clickableButton)
            }
        }
    }

    var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: Constants.rowSpacing) {
            Button {
                onDeleteAccount?()
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .foregroundColor(.dangerText).frame(width: Constants.iconWidth)
                    Text("Hesabı Sil")
                        .foregroundStyle(.dangerText)
                }
            }
            .accessibilityIdentifier("permissions_delete_account_button")
            Text("Hesabınız ve buluta kaydedilen tüm verileriniz kalıcı olarak silinir. Cihazınızdaki veriler etkilenmez.")
                .foregroundStyle(.forestText)
                .scaledFont(size: Constants.descriptionFontSize)
        }
    }

}

#Preview {
    ManagePermissionsUI(
        isAnalyticsEnabled: .constant(true),
        trackingStatusDescription: "İzin verildi",
        onOpenSystemSettings: { },
        onDeleteAccount: { },
        onClose: { }
    )
}
