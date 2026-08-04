//
//  ForestRestoreProgressView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.08.2026.
//

import SwiftUI
import Combine

// MARK: - CONSTANTS

private extension ForestRestoreProgressView {
    enum Constants {
        static let waitTimeout: TimeInterval = 5.0
        static let infoMessageDuration: TimeInterval = 2.0
    }
}

/// Popup shown while asset downloads (hydration) run after the cloud forest has been accepted.
///
/// Behaviour:
/// - If hydration finishes within 5 seconds, the popup closes normally.
/// - If the 5 seconds elapse, a "will be downloaded in the background" notice is shown and the
///   popup closes; the download is NOT cancelled and keeps running. The 5 s is a timeout on the
///   waiting, not on the download.
/// - If the user taps "Cancel", hydration is cancelled; the entities that did not download stay at
///   assetReady = false and are fetched on the next hydration pass.
struct ForestRestoreProgressView: View {

    let statePublisher: AnyPublisher<AssetHydrationState, Never>
    let onCancel: () -> Void
    let onFinished: () -> Void

    @State private var timedOut = false
    @State private var isDismissed = false

    var body: some View {
        VStack(spacing: 20) {
            if timedOut {
                Image(systemName: "arrow.down.circle")
                    .font(.largeTitle)
                    .foregroundColor(.logoGreen)
                Text("Remaining items will be downloaded in the background.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                ProgressView()
                    .controlSize(.large)
                Text("Preparing your forest…")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Downloading your forest's animals and plants.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    guard !isDismissed else { return }
                    isDismissed = true
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(Color.backgroundSystem)
        .cornerRadius(20)
        .onReceive(statePublisher.receive(on: DispatchQueue.main)) { state in
            if case .finished = state {
                finish()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(Constants.waitTimeout * 1_000_000_000))
            guard !isDismissed else { return }
            // Waiting timeout: the download keeps running in the background, we just stop holding the user here.
            withAnimation { timedOut = true }
            try? await Task.sleep(nanoseconds: UInt64(Constants.infoMessageDuration * 1_000_000_000))
            finish()
        }
    }

    private func finish() {
        guard !isDismissed else { return }
        isDismissed = true
        onFinished()
    }
}

#Preview {
    ForestRestoreProgressView(
        statePublisher: Just(AssetHydrationState.running).eraseToAnyPublisher(),
        onCancel: {},
        onFinished: {}
    )
}
