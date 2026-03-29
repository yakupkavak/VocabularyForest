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
    let backgroundHeight = 0.8
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { geometry in
            
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            ZStack {
                Image("krem").resizable().frame(width: screenWidth * 0.96 , height: screenHeight * backgroundHeight)
                    .overlay(alignment: .top) {
                        Text("Daily Reward")
                            .offset(y: geometry.size.height * 0.0475)
                            .font(
                                .system(size: 22, weight: .heavy, design: .rounded)
                            )
                            .foregroundStyle(
                                .white.opacity(0.95)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 3)
                            
                    }
                VStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Play everyday and get additional bonuses").font(.system(size: 20, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 2)
                         
                        Spacer()
                    }
                    .overlay(alignment: .bottomTrailing, content: {
                        Button {
                            print("clsoe")
                        } label: {
                            Image("close_button_gold")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.07)
                                .foregroundStyle(
                                    goldGradient
                                )
                                .shadow(color: .black.opacity(0.3), radius: 1).offset(x: -geometry.size.width * 0.1, y: -geometry.size.height * 0.01)
                        }
                    })
                    .padding()
                    .padding(.top, -16)
                        
                    Grid(horizontalSpacing: 16, verticalSpacing: 34) {
                        GridRow {
                            DailyCard(parentWidth: screenWidth, model: cardList[0]) {
                                print("yakup")
                            }
                            DailyCard(parentWidth: screenWidth, model: cardList[1]) {
                                print("yakup")
                            }
                            DailyCard(parentWidth: screenWidth, model: cardList[2]) {
                                print("yakup")
                            }
                        }
                        GridRow {
                            DailyCard(parentWidth: screenWidth, model: cardList[3]) {
                                print("yakup")
                            }
                            DailyCard(parentWidth: screenWidth, model: cardList[4]) {
                                print("yakup")
                            }
                            DailyCard(parentWidth: screenWidth, model: cardList[5]) {
                                print("yakup")
                            }
                        }
                    }
                    DailyCard(parentWidth: screenWidth, model: cardList[6], verticalPadding: 10, onClick:  {
                        print("yakup")
                    }, isSpecial: true).padding(.top)
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }
                .offset(y: 50)
            }
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
