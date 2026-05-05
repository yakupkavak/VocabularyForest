//
//  StarterCompanionSelectionUI.swift
//  VocabularyForest
//
//  Created by Codex on 3.05.2026.
//

import SwiftUI

struct StarterCompanionSelectionUI: View {
    @StateObject private var viewModel = StarterCompanionSelectionViewModel()
    let onCompleted: () -> Void

    init(onCompleted: @escaping () -> Void = {}) {
        self.onCompleted = onCompleted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundSystem.ignoresSafeArea()

                VStack(spacing: 18) {
                    Text("Başlangıç Dostunu Seç")
                        .font(.system(size: 30, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Bu dost oyuna seninle başlar. İleride görevlerden yenilerini alabilirsin.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 12)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.options, id: \.id) { option in
                                    starterRow(option: option)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            viewModel.loadOptionsIfNeeded()
        }
        .onChange(of: viewModel.didCompleteSelection) { isCompleted in
            if isCompleted {
                onCompleted()
            }
        }
    }
}

private extension StarterCompanionSelectionUI {
    func starterRow(option: StarterCompanionModel) -> some View {
        let displayName = option.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (displayName?.isEmpty == false ? displayName! : option.modelKey)
        let previewImageName = (option.previewImageName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? option.previewImageName!
            : option.modelKey

        return Button {
            viewModel.selectStarter(option)
        } label: {
            HStack(spacing: 14) {
                Image(previewImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white.opacity(0.65))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(sourceTypeText(for: option.mediaSourceType))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.selectedStarterID == option.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
    }

    func sourceTypeText(for sourceType: RewardMediaSourceType) -> String {
        switch sourceType {
        case .localAsset:
            return String(localized: "Comes from local app assets")
        case .remoteBundle:
            return String(localized: "Will use downloaded media bundle")
        }
    }
}

#Preview {
    StarterCompanionSelectionUI()
}
