//
//  DailyRewardCard.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.03.2026.
//

import SwiftUI

struct DailyCard: View {
    
    // MARK: - PROPERTIES
    
    var parentWidth: CGFloat
    var model: WeeklyDailyCardModel
    var verticalPadding: CGFloat = 8
    var onClick: () -> Void
    var isSpecial: Bool = false
    
    // MARK: - UI
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(model.bounty.rewardImage).resizable().scaledToFit().frame(width: parentWidth * 0.12)
            if let rewardCount = model.bounty.rewardCount {
                Text("x\(rewardCount)").outlinedLargeTitle().offset(x: 15, y: 5)
            }
        }
        .compositingGroup()
        .padding(8)
        .padding(verticalPadding)
        .padding(.top, 10)
        .padding(.vertical, 6)
        .background(
            RadialGradient(colors: model.status == .ready ? [.backgroundSystem, .brown500, .claimedText] : [.backgroundSystem, .brown700, .claimedText], center: .center, startRadius: 30, endRadius: 150)
        )
        .borderShape(radius: 24)
        .outlinedLine(radius: model.status == .ready ? 2 : 0.2, color: model.status == .ready ? .darkGren.opacity(0.3) : .orange.opacity(0.3))
        .shadow(color: Color.orange.opacity( model.status == .ready ? 0 : 0.4), radius: 4, x: 0, y: 0)
        .overlay(alignment: .top) {
            DailyHeader(text: String(localized: "Day \(model.day)"), isReady: (model.status == .ready)).alignmentGuide(.top) { dimensions in
                dimensions.height / 2
            }
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .bottomTrailing) {
            if model.status == .claimed {
                Image("tick")
                    .resizable()
                    .scaledToFit()
                    .frame(width: parentWidth * 0.12)
                    .offset(x: parentWidth * 0.04, y: parentWidth * 0.03)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 0)
                    
            } else if model.status == .locked {
                Image("locked")
                    .resizable()
                    .scaledToFit()
                    .frame(width: parentWidth * 0.1)
                    .offset(x: parentWidth * 0.05, y: parentWidth * 0.05)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 0)
                    .rotationEffect(.degrees(15))
            }
        }
        .compositingGroup()
        .opacity(model.status == .passed || model.status == .claimed  ? 0.8 : 1.0)

        .onTapGesture {
            onClick()
        }
    }
}

struct DailyHeader: View {
    
    var text: String
    var isReady: Bool
    
    var body: some View {
        Image(isReady ? "success_day_header": "day_header").resizable().scaledToFit()
            .shadow(color: .white, radius: 0.7)
            .frame(width: 80)
            .overlay(alignment: .center) {
                Text(text).font(.title3).foregroundStyle(goldGradient).fontWeight(.bold)
                .outlinedLine(radius: 0.2, color: .black.opacity(0.1))
                .offset(y: -2)
            }.offset(y: 8)
    }
}

#Preview {
    let goldModel = WeeklyDailyCardModel(day: 1, bounty: .chest(model: .gold), status: .ready)
    let waterModel = WeeklyDailyCardModel(day: 1, bounty: .standart(model: .gold(count: 200)), status: .passed)
    HStack {
        Spacer()
        VStack {
            Spacer()
            DailyCard(parentWidth: UIScreen.main.bounds.width, model: waterModel) {
                print("yakup")
            }
            Spacer()
        }
        Spacer()
        DailyCard(parentWidth: UIScreen.main.bounds.width, model: goldModel) {
            print("yakup")
        }
        Spacer()
    }
    .background(.blue)
}
