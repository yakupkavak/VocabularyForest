//
//  ForestQuestUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI

// MARK: - CONSTANTS

private extension ForestQuestUI {
    enum Constant {
        static let questTypeList: [QuestType] = [.daily, .weekly, .monthly, .special]
    }
}

// MARK: - QuestProgressBar

struct QuestProgressBar: View {
    var current: Int
    var target: Int
    var color: Color = .green
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return Double(current) / Double(target)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Progress")
                    .font(.caption).bold()
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(current)/\(target)")
                    .font(.caption).bold()
                    .foregroundStyle(.white)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.2))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * min(progress, 1.0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .frame(height: 12)
        }
    }
}

struct QuestRewardView: View {
    
    //MARK: - PROPERTIES
    
    let reward: QuestRewardModel
    
    //MARK: - UI
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [.yellow.opacity(0.6), .orange], center: .center, startRadius: 2, endRadius: 30)
                    )
                    .frame(width: 50, height: 50)
                    .shadow(radius: 2)
                switch reward {
                case .animal(let name), .plant(let name), .sculpture(let name):
                    Image(name).resizable().scaledToFit().frame(width: 35, height: 35).shadow(radius: 2)
                case .water:
                    Image(systemName: "drop.fill").resizable().scaledToFit().frame(width: 24, height: 24).foregroundStyle(.blue)
                case .gold:
                    Image(systemName: "circle.circle.fill").resizable().scaledToFit().frame(width: 24, height: 24).foregroundStyle(.yellow)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Reward")
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(.white.opacity(0.8))
                
                switch reward {
                case .animal, .plant, .sculpture:
                    Text(reward.valueString.capitalized).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.brown)
                case .water(let count):
                    Text("\(count) Water Drops").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.blue)
                case .gold(let count):
                    Text("\(count) Gold").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.orange)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - QUEST ROW

struct QuestRow: View {
    
    @State private var showDetail = false
    var onRewardClaim: (QuestModel) -> Void
    var quest: QuestModel
    
    var statusColor: Color {
        switch quest.status {
        case .locked: return .gray
        case .active: return .yellow
        case .completed: return .green
        case .claimed: return .selectedButton
        }
    }
    
    var statusText: String {
        switch quest.status {
        case .locked: return "Locked"
        case .active: return "In Progress"
        case .completed: return "Completed!"
        case .claimed: return "Claimed"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                if quest.status != .locked {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showDetail.toggle()
                    }
                }
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        switch quest.reward {
                        case .animal(let name), .plant(let name), .sculpture(let name):
                            Image(name).resizable().scaledToFit().frame(width: 35, height: 35).shadow(radius: 2)
                        case .water:
                            Image(systemName: "drop.fill").resizable().scaledToFit().frame(width: 24, height: 24).foregroundStyle(.blue)
                        case .gold:
                            Image(systemName: "circle.circle.fill").resizable().scaledToFit().frame(width: 24, height: 24).foregroundStyle(.yellow)
                        }
                        if quest.status == .locked {
                            Image(systemName: "lock.fill").foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quest.title)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text(statusText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                    }
                    
                    Spacer()
                    if quest.status != .locked {
                        Image(systemName: "chevron.down")
                            .font(.title3.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .rotationEffect(.degrees(showDetail ? 180 : 0))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .opacity(quest.status == .locked ? 0.8 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(quest.status == .locked)
            if showDetail {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        Image(systemName: "scroll.fill").foregroundStyle(statusColor)
                        Text(quest.description)
                            .font(.subheadline).foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Image(systemName: "scroll.fill").foregroundStyle(statusColor)
                        if #available(iOS 17.0, *) {
                            (Text("Learning Mode: ")
                                .foregroundStyle(.white.opacity(0.9)).font(.subheadline)
                             +
                             Text(quest.questionType.valueForCoreData.capitalized)
                                .foregroundStyle(statusColor)
                                .bold())
                            .font(.caption)
                        }
                        Spacer()
                    }
                    
                    HStack(alignment: .center) {
                        Image(systemName: "scroll.fill").foregroundStyle(statusColor)
                        if #available(iOS 17.0, *) {
                            (Text("Game Level: ")
                                .foregroundStyle(.white.opacity(0.9)).font(.subheadline)
                             +
                             Text(quest.gameLevel.valueForCoreData.capitalized)
                                .foregroundStyle(statusColor)
                                .bold())
                            .font(.caption)
                        }
                        Spacer()
                    }
                                        
                    QuestProgressBar(
                        current: quest.currentProgressCount,
                        target: quest.targetCount,
                        color: statusColor
                    )
                                        
                    HStack {
                        Spacer()
                        QuestRewardView(reward: quest.reward)
                        Spacer()
                    }
                    
                    if quest.status == .completed {
                        Button {
                            onRewardClaim(quest)
                        } label: {
                            Text("Claim reward")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.5))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .padding(.top, 8)
                    } else if quest.status == .claimed || quest.status == .active {
                        Text(quest.status == .claimed ? "Reward claimed" : "In progress")
                            .font(.headline.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(quest.status == .claimed ? Color.gray.opacity(0.5) : Color.yellow.opacity(0.5)
                            )
                            .cornerRadius(12)
                            .padding(.top, 8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .zIndex(-1)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brown.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - MAIN SCREEN

struct ForestQuestUI: View {
    
    // MARK: - PROPERTIES
    
    @State private var showDailyQuest = false
    @State private var showWeeklyQuest = false
    @State private var showMonthlyQuest = false
    @State private var showSpecialQuest = false
    @Binding var showQuest: Bool
    var dailyQuests: [QuestModel]?
    var weeklyQuests: [QuestModel]?
    var monthlyQuests: [QuestModel]?
    var specialQuests: [QuestModel]?
    var claimReward: (QuestModel) -> Void
    
    // MARK: - UI
    
    var body: some View {
        VStack {
            if showDailyQuest {
                questListView(title: "Daily Quests", quests: dailyQuests, closeAction: { showDailyQuest = false })
            } else if showWeeklyQuest {
                questListView(title: "Weekly Quests", quests: weeklyQuests, closeAction: { showWeeklyQuest = false })
            } else if showMonthlyQuest {
                questListView(title: "Monthly Quests", quests: monthlyQuests, closeAction: { showMonthlyQuest = false })
            } else if showSpecialQuest {
                questListView(title: "Special Quests", quests: specialQuests, closeAction: { showSpecialQuest = false })
            } else {
                mainMenu
            }
        }
        .padding()
        .background(.brown.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color("brown300"), lineWidth: 4)
        )
        .zIndex(3.0)
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .overlay(alignment: .topTrailing) {
            Button {
                showQuest = false
                showDailyQuest = false
                showWeeklyQuest = false
                showMonthlyQuest = false
                showSpecialQuest = false
            } label: {
                Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36).offset(x: 12, y: -12)
            }
        }
    }
    
    @ViewBuilder
    func questListView(title: String, quests: [QuestModel]?, closeAction: @escaping () -> Void) -> some View {
        VStack {
            ZStack {
                Image("title_header").resizable().scaledToFit().frame(height: 50)
                Text(title).foregroundStyle(.white).font(.system(size: 20, weight: .bold))
            }.padding(.bottom)
            
            if let list = quests, !list.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 32) {
                        ForEach(list, id: \.self) { quest in
                            QuestRow(onRewardClaim: { model in
                                claimReward(model)
                            }, quest: quest)
                        }
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
            } else {
                Text("No quests available.")
                    .foregroundStyle(.white.opacity(0.7))
                    .padding()
            }
            Button(action: closeAction) {
                Text("Return back")
                    .foregroundStyle(.clickableText)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.brown700.opacity(0.5))
                    .cornerRadius(16)
            }.padding(.top)
        }
    }
    
    var mainMenu: some View {
        VStack {
            ZStack {
                Image("title_header").resizable().scaledToFit().frame(height: 50)
                Text("Quests").foregroundStyle(.white).font(.system(size: 24, weight: .bold))
            }.padding(.bottom)
            
            ForEach(Constant.questTypeList, id: \.self) { model in
                settingsRow(model: SettingsModel<QuestType>(title: model.localizedTitle, icon: model.imageIconName, color: model.backgroundColor, type: model))
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        switch model {
                        case .daily: showDailyQuest = true
                        case .weekly: showWeeklyQuest = true
                        case .monthly: showMonthlyQuest = true
                        case .special: showSpecialQuest = true
                        }
                    }
            }
        }
    }
}

#Preview {
    @State var show = true
    ForestQuestUI(
        showQuest: $show,
        dailyQuests: [QuestModel(
            id: UUID(),
            type: .weekly,
            title: "weekly",
            description: "Buraya açıklamalar geliyor",
            reward: .gold(count: 5),
            status: .locked,
            targetCount: 10,
            currentProgressCount: 0,
            questionType: .competitive,
            battleEnemyModel: .classic,
            gameLevel: .easy
        ),
          QuestModel(
            id: UUID(),
            type: .daily,
            title: "Daily",
            description: "Buraya açıklamalar geliyor",
            reward: .water(count: 5),
            status: .locked,
            targetCount: 10,
            currentProgressCount: 0,
            questionType: .competitive,
            battleEnemyModel: .classic,
            gameLevel: .easy
          ),
          QuestModel(
            id: UUID(),
            type: .daily,
            title: "Daily",
            description: "Buraya açıklamalar geliyor",
            reward: .gold(count: 5),
            status: .locked,
            targetCount: 10,
            currentProgressCount: 0,
            questionType: .competitive,
            battleEnemyModel: .classic,
            gameLevel: .easy
          ),
                      QuestModel(
                        id: UUID(),
                        type: .daily,
                        title: "Daily",
                        description: "Buraya açıklamalar geliyor",
                        reward: .gold(count: 5),
                        status: .locked,
                        targetCount: 10,
                        currentProgressCount: 0,
                        questionType: .competitive,
                        battleEnemyModel: .classic,
                        gameLevel: .easy
                      ),
                      QuestModel(
                        id: UUID(),
                        type: .daily,
                        title: "Daily",
                        description: "Buraya açıklamalar geliyor",
                        reward: .animal(name: "cat_idle_0"),
                        status: .active,
                        targetCount: 10,
                        currentProgressCount: 5,
                        questionType: .competitive,
                        battleEnemyModel: .classic,
                        gameLevel: .easy
                      ),
                      QuestModel(
                        id: UUID(),
                        type: .daily,
                        title: "Daily",
                        description: "Buraya açıklamalar geliyor",
                        reward: .gold(count: 5),
                        status: .claimed,
                        targetCount: 10,
                        currentProgressCount: 5,
                        questionType: .competitive,
                        battleEnemyModel: .classic,
                        gameLevel: .easy
                      ),
                      QuestModel(
                        id: UUID(),
                        type: .daily,
                        title: "Daily",
                        description: "Buraya açıklamalar geliyor",
                        reward: .water(count: 5),
                        status: .completed,
                        targetCount: 10,
                        currentProgressCount: 5,
                        questionType: .competitive,
                        battleEnemyModel: .classic,
                        gameLevel: .easy
                      )], claimReward: { model in
                          print(model)
                      }
    )
}
