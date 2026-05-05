//
//  Untitled.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.04.2026.
//

import SwiftUI

struct AdventureFlowPath: Shape {
    var neckRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let centerX = rect.midX
        
        let neckWidth = w * neckRatio
        let bellyWidth = w
        
        path.move(to: CGPoint(x: centerX - neckWidth / 2, y: 0))
        
        path.addCurve(to: CGPoint(x: centerX - bellyWidth / 2, y: h * 0.5),
                      control1: CGPoint(x: centerX - neckWidth / 2, y: h * 0.25),
                      control2: CGPoint(x: centerX - bellyWidth / 2, y: h * 0.25))
        
        path.addCurve(to: CGPoint(x: centerX - neckWidth / 2, y: h),
                      control1: CGPoint(x: centerX - bellyWidth / 2, y: h * 0.75),
                      control2: CGPoint(x: centerX - neckWidth / 2, y: h * 0.75))
        
        path.addLine(to: CGPoint(x: centerX + neckWidth / 2, y: h))
        
        path.addCurve(to: CGPoint(x: centerX + bellyWidth / 2, y: h * 0.5),
                      control1: CGPoint(x: centerX + neckWidth / 2, y: h * 0.75),
                      control2: CGPoint(x: centerX + bellyWidth / 2, y: h * 0.75))
        
        path.addCurve(to: CGPoint(x: centerX + neckWidth / 2, y: 0),
                      control1: CGPoint(x: centerX + bellyWidth / 2, y: h * 0.25),
                      control2: CGPoint(x: centerX + neckWidth / 2, y: h * 0.25))
        
        path.closeSubpath()
        return path
    }
}

struct AdventurePassBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius = rect.height * 0.3
        let tipHeight = rect.height * 0.2
        let tipWidth = rect.width * 0.4
        let baseBottomY = rect.height - tipHeight
        let tipCenterX = rect.midX

        var path = Path()
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: baseBottomY - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: baseBottomY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: tipCenterX + tipWidth / 2, y: baseBottomY))
        path.addQuadCurve(
            to: CGPoint(x: tipCenterX, y: rect.height),
            control: CGPoint(x: tipCenterX + (tipWidth * 0.2), y: rect.height)
        )
        path.addQuadCurve(
            to: CGPoint(x: tipCenterX - tipWidth / 2, y: baseBottomY),
            control: CGPoint(x: tipCenterX - (tipWidth * 0.2), y: rect.height)
        )
        path.addLine(to: CGPoint(x: cornerRadius, y: baseBottomY))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: baseBottomY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct AdventureRewardCardShape: Shape {
    let notchSide: AdventureTicketNotchSide

    func path(in rect: CGRect) -> Path {
        let cornerRadius = min(rect.width, rect.height) * 0.24
        let bumpWidth = rect.width * 0.12
        let bumpHeight = rect.height * 0.35
        let midY = rect.midY
        let halfBump = bumpHeight / 2

        var path = Path()

        if notchSide == .right {
            path.move(to: CGPoint(x: cornerRadius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
            path.addArc(
                center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.width, y: midY - halfBump))
            path.addQuadCurve(
                to: CGPoint(x: rect.width + bumpWidth, y: midY),
                control: CGPoint(x: rect.width + bumpWidth, y: midY - (halfBump * 0.2))
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: midY + halfBump),
                control: CGPoint(x: rect.width + bumpWidth, y: midY + (halfBump * 0.2))
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
            path.addArc(
                center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
            path.addArc(
                center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            path.addArc(
                center: CGPoint(x: cornerRadius, y: cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        } else {
            path.move(to: CGPoint(x: cornerRadius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
            path.addArc(
                center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
            path.addArc(
                center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
            path.addArc(
                center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: 0, y: midY + halfBump))
            path.addQuadCurve(
                to: CGPoint(x: -bumpWidth, y: midY),
                control: CGPoint(x: -bumpWidth, y: midY + (halfBump * 0.2))
            )
            path.addQuadCurve(
                to: CGPoint(x: 0, y: midY - halfBump),
                control: CGPoint(x: -bumpWidth, y: midY - (halfBump * 0.2))
            )
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            path.addArc(
                center: CGPoint(x: cornerRadius, y: cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }

        path.closeSubpath()
        return path
    }
}
