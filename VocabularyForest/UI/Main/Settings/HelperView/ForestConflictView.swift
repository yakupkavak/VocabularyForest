//
//  ForestConflictView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.04.2026.
//

import SwiftUI

enum ForestSource {
    case local
    case cloud
}

struct ForestConflictView: View {
    let localForest: SafeForestModel
    let cloudForest: SafeForestModel
    
    let onResolve: (ForestSource) -> Void
    
    @State private var selectedSource: ForestSource? = nil
    @State private var confirmText: String = ""
    @FocusState private var isInputFocused: Bool
    
    // MARK: - Localization Support
    
    private var expectedKeyword: String {
        NSLocalizedString("conflict_confirm_keyword", value: "confirm", comment: "Keyword to type for confirmation")
    }
    
    private var isConfirmed: Bool {
        guard selectedSource != nil else { return false }
        let cleanInput = confirmText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanExpected = expectedKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanInput.caseInsensitiveCompare(cleanExpected) == .orderedSame
    }
    
    // MARK: - VIEW
    
    var body: some View {
        ZStack {
            Color.backgroundSystem
                .ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        forestCardsSection
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        confirmationSection
                        confirmButton
                    }
                    .padding(.top, 64)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 500)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isInputFocused) { isFocused in
                    guard isFocused else { return }
                    // Wait one runloop so the keyboard safe area is applied before scrolling
                    Task { @MainActor in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(Constants.confirmButtonId, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - VIEW COMPONENTS

private extension ForestConflictView {
    
    var headerSection: some View {
        VStack(spacing: 8) {
            Text("Conflict Detected")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Different forest records found on your device and in the cloud. Which one do you want to keep?\n\n**Warning: This action cannot be undone. The unselected forest will be permanently deleted.**")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
    }
    
    var forestCardsSection: some View {
        HStack(spacing: 12) {
            forestCard(
                title: String(localized: "Local Forest"),
                forest: localForest,
                source: .local,
                icon: "iphone"
            )
            
            forestCard(
                title: String(localized: "Cloud Forest"),
                forest: cloudForest,
                source: .cloud,
                icon: "icloud.fill"
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
    
    var confirmationSection: some View {
        VStack(spacing: 12) {
            Text("Type **'\(expectedKeyword)'** to confirm your selection:")
                .font(.callout)
                .foregroundColor(.primary)
            
            TextField(expectedKeyword, text: $confirmText)
                .focused($isInputFocused)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { isInputFocused = false }
                .frame(maxWidth: 250)
        }
    }
    
    var confirmButton: some View {
        Button {
            guard let selected = selectedSource else { return }
            isInputFocused = false
            onResolve(selected)
        } label: {
            Text("Confirm Selection")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isConfirmed ? Color.logoGreen : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!isConfirmed)
        .padding(.horizontal, 30)
        .id(Constants.confirmButtonId)
    }
    
    @ViewBuilder
    private func forestCard(title: String, forest: SafeForestModel, source: ForestSource, icon: String) -> some View {
        let isSelected = selectedSource == source
        
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .logoGreen : .gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            VStack(alignment: .leading, spacing: 6) {
                customStatRow(assetIcon: "gold_icon", text: "\(forest.moneyValue)")
                customStatRow(assetIcon: "diamond_icon", text: "\(forest.diamondValue)")
                customStatRow(assetIcon: "water_icon", text: "\(forest.rainValue)")
                statRow(icon: "heart.fill", color: .red, text: "%\(forest.landHealthPercent)")
                
                Divider().padding(.vertical, 2)
                
                statRow(icon: "tree.fill", color: .green, text: "\(forest.trees.count) Plants")
                statRow(icon: "pawprint.fill", color: .orange, text: "\(forest.animals.count) Animals")
                statRow(icon: "building.columns.fill", color: .gray, text: "\(forest.sculptures.count) Sculptures")
                statRow(icon: "checkmark.seal.fill", color: .mint, text: "\(forest.quests.count) Quests")
                
                Divider().padding(.vertical, 2)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                    Text(forest.lastUpdatedDate, format: .dateTime.month().day().hour().minute())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .font(.caption2)
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(isSelected ? Color.logoGreen.opacity(0.1) : Color.white.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.logoGreen : Color.clear, lineWidth: 2.5)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSource = source
            }
        }
    }
    
    @ViewBuilder
    private func statRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16, alignment: .center)
            Text(text)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private func customStatRow(assetIcon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(assetIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16, alignment: .center)
            Text(text)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - CONSTANTS

private extension ForestConflictView {
    enum Constants {
        static let confirmButtonId = "confirmButton"
    }
}

// MARK: - PREVIEW

#Preview {
    ForestConflictView(
        localForest: SafeForestModel(
            forestId: UUID(),
            ownerId: "UUID()",
            rainValue: 120,
            moneyValue: 1500,
            diamondValue: 50,
            landHealthPercent: 85,
            landStatus: true,
            isRaining: false,
            lastRainUpdateDate: Date(),
            lastDailyResetDate: Date(),
            lastWeeklyResetDate: Date(),
            lastMonthlyResetDate: Date(),
            quests: [],
            sculptures: [],
            trees: [],
            animals: [],
            player: PlayerModel(name: "Ichigo", lastUpdateDate: Date()),
            lastUpdatedDate: Date(),
            lastSyncCloudTime: Date(),
            dailyActivities: DailyActivitiesModel(
                adventureSeasonID: nil,
                claimedLongTiers: nil,
                claimedShortTiers: nil,
                monthlyLongLearnedCount: 0,
                monthlyShortLearnedCount: 0,
                weeklyStreakLastClaimDate: nil,
                weeklyStreakCurrentDay: 10,
                lastFetchDate: nil,
                fixedTimeZone: nil,
                dailySpinLastUsedDate: nil,
                lastUpdatedDate: Date()
            )
        ),
        cloudForest: SafeForestModel(
            forestId: UUID(),
            ownerId: "UUID()",
            rainValue: 300,
            moneyValue: 2400,
            diamondValue: 150,
            landHealthPercent: 100,
            landStatus: true,
            isRaining: true,
            lastRainUpdateDate: Date(),
            lastDailyResetDate: Date(),
            lastWeeklyResetDate: Date(),
            lastMonthlyResetDate: Date(),
            quests: [],
            sculptures: [],
            trees: [],
            animals: [],
            player: PlayerModel(name: "Ichigo", lastUpdateDate: Date()),
            lastUpdatedDate: Date(),
            lastSyncCloudTime: Date(),
            dailyActivities: DailyActivitiesModel(
                adventureSeasonID: nil,
                claimedLongTiers: nil,
                claimedShortTiers: nil,
                monthlyLongLearnedCount: 0,
                monthlyShortLearnedCount: 0,
                weeklyStreakLastClaimDate: nil,
                weeklyStreakCurrentDay: 10,
                lastFetchDate: nil,
                fixedTimeZone: nil,
                dailySpinLastUsedDate: nil,
                lastUpdatedDate: Date()
            )
        ),
        onResolve: { _ in
        }
    )
}
