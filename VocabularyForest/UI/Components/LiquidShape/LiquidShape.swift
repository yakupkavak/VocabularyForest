//
//  LiquidShape.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.10.2025.
//

import SwiftUI

/// Page mask whose trailing edge bends inward as the user drags, revealing the page underneath.
///
/// `offset` is expressed in logical space: a negative width always means "dragged toward the next
/// page", whichever way the layout runs. SwiftUI never mirrors a custom `Shape`, so RTL is handled
/// here by flipping the finished path — the curve then lands on the same edge as the drag handle
/// instead of the opposite one.
struct LiquidShape: Shape {

    // MARK: - PROPERTIES

    var offset: CGSize
    var currentPoint: CGFloat
    var curveCenterY: CGFloat
    var waveHeight: CGFloat = 100
    var layoutDirection: LayoutDirection = .leftToRight

    var animatableData: AnimatablePair<CGSize.AnimatableData, CGFloat> {
        get {
            return AnimatablePair(offset.animatableData, currentPoint)
        }
        set {
            offset.animatableData = newValue.first
            currentPoint = newValue.second
        }
    }

    // MARK: - VIEW

    func path(in rect: CGRect) -> Path {
        let path = logicalPath(in: rect)
        guard layoutDirection == .rightToLeft else { return path }

        return path.applying(
            CGAffineTransform(scaleX: -1, y: 1)
                .concatenating(CGAffineTransform(translationX: rect.width, y: 0))
        )
    }
}

// MARK: - HELPERS

private extension LiquidShape {

    /// Curve drawn as if the layout ran left-to-right; `path(in:)` mirrors it when it does not.
    func logicalPath(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width + (-offset.width > 0 ? offset.width : 0)

            let thresholdCurve = curveCenterY - (waveHeight / 2)
            let endCurve = curveCenterY + (waveHeight / 2)

            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))

            let from = thresholdCurve + offset.height + (-offset.width)
            path.move(to: CGPoint(x: rect.width, y: from > thresholdCurve ? thresholdCurve : from))

            var to = endCurve + (offset.height) + (-offset.width)
            to = to < endCurve ? endCurve : to

            let mid: CGFloat = thresholdCurve + ((to - thresholdCurve) / 2)

            path.addCurve(to: CGPoint(x: rect.width, y: to),
                          control1: CGPoint(x: width - currentPoint, y: mid),
                          control2: CGPoint(x: width - currentPoint, y: mid))
        }
    }
}
