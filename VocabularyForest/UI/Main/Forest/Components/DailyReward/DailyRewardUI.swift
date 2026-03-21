//
//  DailyRewardUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.03.2026.
//

import SwiftUI

struct DailyRewardUI: View {
    
    // MARK: - INIT
    
    let cardList: [DailyCardModel]
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            Image("dailytable").resizable().frame(width: UIScreen.main.bounds.width,height: 600)
                .overlay(alignment: .top) {
                    Text("Daily Reward").offset(y: 40)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            titleGradient
                        )
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.3), radius: 0.5, x: 0, y: 1)
                }
            VStack {
                Spacer()
                Spacer()
                HStack {
                    Spacer()
                    Text("Play everyday and get additional bonuses").font(.system(size: 20, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(goldGradient)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.3), radius: 0.5, x: 0, y: 1)
                    Spacer()
                }
                .overlay(alignment: .bottomTrailing, content: {
                    Image("close_button_gold")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                        .foregroundStyle(
                            goldGradient
                        )
                        .shadow(color: .black.opacity(0.5), radius: 1).offset(x: -35, y: -5)
                })
                .padding()
                .padding(.top, -16)
                    
                Grid(horizontalSpacing: 16, verticalSpacing: 34) {
                    GridRow {
                        DailyCard(model: cardList[0]) {
                            print("yakup")
                        }
                        DailyCard(model: cardList[1]) {
                            print("yakup")
                        }
                        DailyCard(model: cardList[2]) {
                            print("yakup")
                        }
                    }
                    GridRow {
                        DailyCard(model: cardList[3]) {
                            print("yakup")
                        }
                        DailyCard(model: cardList[4]) {
                            print("yakup")
                        }
                        DailyCard(model: cardList[5]) {
                            print("yakup")
                        }
                    }
                }
                DailyCard(model: cardList[6], verticalPadding: 12) {
                    print("yakup")
                }.padding(.top)
                Spacer()
                Spacer()
                Spacer()
            }
            .offset(y: 50)
        }
        
        
    }
}

#Preview {
    let goldModel = DailyCardModel(day: 1, bounty: .chest(model: .gold), status: .claimed)
    let waterModel = DailyCardModel(day: 2, bounty: .standart(model: .gold(count: 200)), status: .passed)
    let goldModel1 = DailyCardModel(day: 3, bounty: .chest(model: .gold), status: .claimed)
    let waterModel2 = DailyCardModel(day: 4, bounty: .standart(model: .gold(count: 200)), status: .claimed)
    let goldModel3 = DailyCardModel(day: 5, bounty: .chest(model: .gold), status: .ready)
    let waterModel3 = DailyCardModel(day: 6, bounty: .standart(model: .gold(count: 200)), status: .locked)
    let chest1 = DailyCardModel(day: 7, bounty: .standart(model: .gold(count: 200)), status: .locked)
    let list = [goldModel,waterModel,goldModel1,waterModel2,goldModel3,waterModel3,chest1]
    DailyRewardUI(cardList: list)
}
