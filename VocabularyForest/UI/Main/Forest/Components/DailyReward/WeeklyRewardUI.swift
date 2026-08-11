//
//  WeeklyRewardUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.03.2026.
//

import SwiftUI

// MARK: - WEEKLY REWARD UI

struct WeeklyRewardUI: View {
    
    // MARK: - PROPERTIES
    
    @Binding var isOpen: Bool
    let cardList: [WeeklyDailyCardModel]
    let onClick: (WeeklyDailyCardModel) -> Void
    
    // MARK: - PRIVATE PROPERTIES
    
    private let backgroundHeight = 0.8
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad

    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                mainCard(size: geometry.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .trackScreen(.weeklyReward)
    }
}

// MARK: - UI COMPONENTS

private extension WeeklyRewardUI {
    
    func mainCard(size: CGSize) -> some View {
        ZStack(alignment: .top) {
            Image("krem")
                .resizable()
                .frame(width: size.width * (isPad ? 0.8 : 0.98), height: size.height * backgroundHeight)
            
            VStack(spacing: 0) {
                titleView(size: size)
                    .padding(.top, size.height * 0.0475)
                
                headerSection(size: size)
                    .padding(.top, size.height * 0.02)
                
                if cardList.count >= 7 {
                    cardsGrid(size: size)
                        .padding(.top, isPad ? 40 : 20)
                }
                
                Spacer()
            }
            .frame(width: size.width * (isPad ? 0.8 : 0.98), height: size.height * backgroundHeight)
        }
    }
    
    func titleView(size: CGSize) -> some View {
        Text("Daily Reward")
            .font(.system(size: isPad ? 40 : 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 3)
    }
    
    func headerSection(size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            HStack {
                Spacer()
                Text("Play everyday and get additional bonuses")
                    .font(.system(size: isPad ? 32 : 18, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 2)
                Spacer()
            }.frame(width: size.width * (isPad ? 0.55 : 0.58)).overlay(alignment: .trailing) {
                Button {
                    isOpen = false
                } label: {
                    Image("close_button_gold")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width * (isPad ? 0.05 : 0.07))
                        .foregroundStyle(goldGradient)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                }
                .offset(x: size.width * (isPad ? -0.00 : 0.07), y: size.height * (isPad ? 0.015 : 0.01))
                .accessibilityLabel(String(localized: "a11y_close"))
            }
            
            
        }
        .padding(.horizontal)
    }
    
    func cardsGrid(size: CGSize) -> some View {
        let parentWidth = size.width * (isPad ? 0.8 : 1.0)
        let horizontalSpacing: CGFloat = isPad ? 40 : 16
        let verticalSpacing: CGFloat = isPad ? 80 : 42
        
        return VStack(spacing: verticalSpacing) {
            HStack(spacing: horizontalSpacing) {
                ForEach(0..<3, id: \.self) { index in
                    DailyCard(parentWidth: parentWidth, model: cardList[index]) {
                        onClick(cardList[index])
                    }
                }
            }
            
            HStack(spacing: horizontalSpacing) {
                ForEach(3..<6, id: \.self) { index in
                    DailyCard(parentWidth: parentWidth, model: cardList[index]) {
                        onClick(cardList[index])
                    }
                }
            }
            
            DailyCard(
                parentWidth: parentWidth,
                model: cardList[6],
                verticalPadding: isPad ? 20 : 10,
                onClick: {
                    onClick(cardList[6])
                },
                isSpecial: true
            )
            .padding(.top, isPad ? 10 : 0)
        }
    }
}

// MARK: - PREVIEW

#Preview {
    /*
    let goldModel = WeeklyDailyCardModel(day: 1, bounty: .chest(model: .gold), status: .claimed)
    let waterModel = WeeklyDailyCardModel(day: 2, bounty: .standart(model: .gold(count: 200)), status: .passed)
    let goldModel1 = WeeklyDailyCardModel(day: 3, bounty: .chest(model: .gold), status: .locked)
    let waterModel2 = WeeklyDailyCardModel(day: 4, bounty: .standart(model: .gold(count: 200)), status: .locked)
    let goldModel3 = WeeklyDailyCardModel(day: 5, bounty: .chest(model: .gold), status: .ready)
    let waterModel3 = WeeklyDailyCardModel(day: 6, bounty: .standart(model: .gold(count: 200)), status: .locked)
    let chest1 = WeeklyDailyCardModel(day: 7, bounty: .standart(model: .gold(count: 200)), status: .locked)
    let list = [goldModel,waterModel,goldModel1,waterModel2,goldModel3,waterModel3,chest1]
    
    WeeklyRewardUI(isOpen: .constant(true), cardList: list) { _ in }
     */
}
