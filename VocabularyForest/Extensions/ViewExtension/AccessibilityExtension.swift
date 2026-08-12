//
//  AccessibilityExtension.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.08.2026.
//

import SwiftUI

// MARK: - VOICEOVER MODIFIERS

extension View {

    /// Collapses children into a single VoiceOver element that reads and activates as a button.
    /// Designed for tappable views built with `.onTapGesture`: VoiceOver's activate gesture
    /// taps the element's center, which still triggers the original gesture.
    /// Pass no label to let the merged child texts speak for themselves.
    /// WARNING: the optional parameters branch the view tree, so switching one
    /// between nil and non-nil at runtime changes the subtree's structural
    /// identity and re-fires its .task/.onAppear — don't gate state on those.
    /// `inputLabels` gives Voice Control users short spoken alternatives
    /// ("Tap <name>") when the accessibility label is a long composed sentence.
    func a11yTapButton(
        _ label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        isSelected: Bool = false,
        inputLabels: [String]? = nil
    ) -> some View {
        accessibilityElement(children: .combine)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .a11yOptionalLabel(label)
            .a11yOptionalValue(value)
            .a11yOptionalHint(hint)
            .a11yOptionalInputLabels(inputLabels)
    }

    /// Collapses children into a single readable, non-interactive element.
    /// Use for rows whose meaning is spread across icons and short texts.
    func a11yGroup(_ label: String? = nil, value: String? = nil) -> some View {
        accessibilityElement(children: .combine)
            .a11yOptionalLabel(label)
            .a11yOptionalValue(value)
    }

    /// Hides purely decorative imagery from assistive technologies so VoiceOver
    /// never reads raw asset names ("bambuuLeft", "elephanthead").
    func a11yDecorative() -> some View {
        accessibilityHidden(true)
    }

    /// Marks an in-app popup as a modal for VoiceOver (focus stays inside)
    /// and wires the two-finger scrub gesture to the popup's close action.
    func a11yModal(onEscape: @escaping () -> Void) -> some View {
        accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape, onEscape)
    }

    /// Marks a title as a header so it appears in the VoiceOver rotor's
    /// "Headings" navigation.
    func a11yHeader() -> some View {
        accessibilityAddTraits(.isHeader)
    }

    /// Binds a text field's visual title as the field's own accessibility label;
    /// hide the visual title with `a11yDecorative` so it is not read twice.
    @ViewBuilder
    func a11yFieldLabel(_ label: String?) -> some View {
        if let label { accessibilityLabel(label) } else { self }
    }
}

// MARK: - HELPERS

private extension View {

    @ViewBuilder
    func a11yOptionalLabel(_ label: String?) -> some View {
        if let label { accessibilityLabel(label) } else { self }
    }

    @ViewBuilder
    func a11yOptionalValue(_ value: String?) -> some View {
        if let value { accessibilityValue(value) } else { self }
    }

    @ViewBuilder
    func a11yOptionalHint(_ hint: String?) -> some View {
        if let hint { accessibilityHint(hint) } else { self }
    }

    @ViewBuilder
    func a11yOptionalInputLabels(_ labels: [String]?) -> some View {
        if let labels { accessibilityInputLabels(labels) } else { self }
    }
}

// MARK: - ANNOUNCER

/// Posts spoken VoiceOver announcements for asynchronous state changes
/// (spin results, rewards, quiz feedback) that are otherwise only visual.
enum A11yAnnouncer {

    static var isVoiceOverOn: Bool { UIAccessibility.isVoiceOverRunning }

    /// Timed UI (toasts, scene bubbles) must not auto-dismiss for assistive-tech
    /// users. Voice Control has no public detection API, so this keys off the
    /// detectable technologies; Voice Control users rely on the visible close
    /// affordances added alongside this flag.
    static var prefersPersistentTimedUI: Bool {
        UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
    }

    static func announce(_ message: String) {
        guard isVoiceOverOn else { return }
        if #available(iOS 17.0, *) {
            AccessibilityNotification.Announcement(message).post()
        } else {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}
