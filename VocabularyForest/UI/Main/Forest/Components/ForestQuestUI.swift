//
//  ForestQuestUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//  Refactored for Responsiveness
//

import SwiftUI

private extension ForestQuestUI {
    enum Constant {
        static let questTypeList: [QuestType] = [.daily, .weekly, .monthly, .special]
    }
}

private struct LayoutConfig {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16
    static let popupWidthRatio: CGFloat = 0.85
    static let popupHeightRatio: CGFloat = 0.70
}

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
                Text(LocalizedStringKey("\(current)/\(target)"))
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
                        .animation(.smooth, value: current)
                }
            }
            .frame(height: 12)
        }
    }
}

func getWaterDropSize(count: Int) -> CGFloat {
    let minCount: CGFloat = 3
    let maxCount: CGFloat = 25
    let minSize: CGFloat = 18
    let maxSize: CGFloat = 36
    let safeCount = CGFloat(min(max(count, Int(minCount)), Int(maxCount)))
    let percentage = (safeCount - minCount) / (maxCount - minCount)
    return minSize + ((maxSize - minSize) * percentage)
}

struct QuestRewardView: View {
    
    let reward: QuestRewardModel
    
    @ScaledMetric var iconSize: CGFloat = 35
    @ScaledMetric var backgroundSize: CGFloat = 50
    @ScaledMetric var smallIconSize: CGFloat = 24
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [.yellow.opacity(0.6), .orange], center: .center, startRadius: 2, endRadius: 30)
                    )
                    .frame(width: backgroundSize, height: backgroundSize)
                    .shadow(radius: 2)
                
                switch reward {
                case .animal(let name), .plant(let name), .sculpture(let name):
                    Image(name).resizable().scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .shadow(radius: 2)
                    
                case .water(let count):
                    let dynamicSize = getWaterDropSize(count: count)
                    
                    Image(systemName: "drop.fill").resizable().scaledToFit()
                        .frame(width: dynamicSize, height: dynamicSize)
                        .foregroundStyle(.blue)
                        .animation(.spring(), value: count)
                    
                case .gold:
                    Image(systemName: "circle.circle.fill").resizable().scaledToFit()
                        .frame(width: smallIconSize, height: smallIconSize)
                        .foregroundStyle(.yellow)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Reward")
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(.white.opacity(0.8))
                
                switch reward {
                case .animal, .plant, .sculpture:
                    Text(LocalizedStringKey(reward.rewardName))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                case .water(let count):
                    Text("\(count) Water Drops")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                case .gold(let count):
                    Text("\(count) Gold")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.3))
        .cornerRadius(12)
    }
}

struct QuestRow: View {
    
    @State private var showDetail = false
    var onQuestSelect: (QuestModel) -> Void
    var onRewardClaim: (QuestModel) -> Void
    var quest: QuestModel
    
    @ScaledMetric var iconBoxSize: CGFloat = 60
    
    func getWaterDropSize(count: Int) -> CGFloat {
        let minCount: CGFloat = 3
        let maxCount: CGFloat = 25
        
        let minSize: CGFloat = iconBoxSize * 0.3
        let maxSize: CGFloat = iconBoxSize * 0.6
        
        let safeCount = CGFloat(min(max(count, Int(minCount)), Int(maxCount)))
        let percentage = (safeCount - minCount) / (maxCount - minCount)
        
        return minSize + ((maxSize - minSize) * percentage)
    }
    
    var statusColor: Color {
        switch quest.status {
        case .locked: return .gray
        case .active: return .yellow
        case .completed: return .green
        case .claimed: return .claimedText
        }
    }
    
    var statusText: String {
        switch quest.status {
        case .locked: return String(localized: "Locked")
        case .active: return String(localized: "In Progress")
        case .completed: return String(localized: "Completed!")
        case .claimed: return String(localized: "Claimed")
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
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: iconBoxSize, height: iconBoxSize)
                        
                        switch quest.reward {
                        case .animal(let name), .plant(let name), .sculpture(let name):
                            Image(name).resizable().scaledToFit()
                                .frame(maxWidth: iconBoxSize * 0.85, maxHeight: iconBoxSize * 0.85)
                                .shadow(radius: 2)
                            
                        case .water(let count):
                            let dynamicSize = getWaterDropSize(count: count)
                            
                            Image(systemName: "drop.fill").resizable().scaledToFit()
                                .frame(width: dynamicSize, height: dynamicSize)
                                .foregroundStyle(.blue)
                            
                        case .gold:
                            Image(systemName: "circle.circle.fill").resizable().scaledToFit()
                                .frame(maxWidth: iconBoxSize * 0.7)
                                .foregroundStyle(.yellow)
                        }
                        
                        if quest.status == .locked {
                            Image(systemName: "lock.fill")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(quest.title))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(LocalizedStringKey(statusText))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(statusColor)
                            .padding(.vertical, 2)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if quest.status != .locked {
                        Image(systemName: "chevron.down")
                            .font(.title3.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .rotationEffect(.degrees(showDetail ? 180 : 0))
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .opacity(quest.status == .locked ? 0.6 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(quest.status == .locked)
            
            if showDetail {
                VStack(alignment: .leading, spacing: 16) {
                    Divider().background(Color.white.opacity(0.2))
                    
                    HStack(alignment: .top) {
                        Image(systemName: "scroll.fill").foregroundStyle(statusColor)
                        Text(LocalizedStringKey(quest.description))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            infoBadge(icon: "burst", title: String(localized: "Enemy:"), value: quest.battleEnemyModel.title.capitalized).padding(.bottom, 1)
                            infoBadge(icon: "brain.head.profile", title: String(localized: "Mode:"), value: quest.questionType.title.firstCapitalized)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            infoBadge(icon: "flag.fill", title: String(localized: "Level:"), value: quest.gameLevel.title.firstCapitalized)
                            Spacer()
                        }
                    }
                    
                    QuestProgressBar(
                        current: quest.currentProgressCount,
                        target: quest.targetCount,
                        color: statusColor
                    )
                    
                    HStack {
                        Spacer()
                        VStack {
                            QuestRewardView(reward: quest.reward)
                            Button {
                                onQuestSelect(quest)
                            } label: {
                                Text("Göreve git").foregroundStyle(Color.clickableText)
                            }
                        }
                        Spacer()
                    }
                    
                    actionButton
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brown.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    func infoBadge(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(statusColor)
            Text(LocalizedStringKey(title)).font(.caption).foregroundStyle(.white.opacity(0.7))
            Text(LocalizedStringKey(value)).font(.caption).bold().foregroundStyle(statusColor)
        }
    }
    
    @ViewBuilder
    var actionButton: some View {
        if quest.status == .completed {
            Button {
                onRewardClaim(quest)
            } label: {
                Text("Claim reward")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
        } else if quest.status == .claimed || quest.status == .active {
            Text(quest.status == .claimed ? "Reward claimed" : "In progress")
                .font(.headline.bold())
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding()
                .background(quest.status == .claimed ? Color.gray.opacity(0.4) : Color.yellow.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct ForestQuestUI: View {
    
    @State private var showDailyQuest = false
    @State private var showWeeklyQuest = false
    @State private var showMonthlyQuest = false
    @State private var showSpecialQuest = false
    @Binding var showQuest: Bool
    var selectQuest: (QuestModel) -> Void
    
    var dailyQuests: [QuestModel]?
    var weeklyQuests: [QuestModel]?
    var monthlyQuests: [QuestModel]?
    var specialQuests: [QuestModel]?
    var claimReward: (QuestModel) -> Void
    
    var isAnySubMenuOpen: Bool {
        showDailyQuest || showWeeklyQuest || showMonthlyQuest || showSpecialQuest
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showQuest = false }
                    }
                
                ZStack {
                    
                    if showDailyQuest {
                        questListView(title: String(localized:"Günlük Görevler"), quests: dailyQuests, closeAction: { withAnimation { showDailyQuest = false } }, geo: geometry)
                            .transition(.move(edge: .trailing))
                            .zIndex(1)
                    } else if showWeeklyQuest {
                        questListView(title: String(localized: "Haftalık Görevler"), quests: weeklyQuests, closeAction: { withAnimation { showWeeklyQuest = false } }, geo: geometry)
                            .transition(.move(edge: .trailing))
                            .zIndex(1)
                    } else if showMonthlyQuest {
                        questListView(title: String(localized:"Aylık Görevler"), quests: monthlyQuests, closeAction: { withAnimation { showMonthlyQuest = false } }, geo: geometry)
                            .transition(.move(edge: .trailing))
                            .zIndex(1)
                    } else if showSpecialQuest {
                        questListView(title: String(localized:"Özel Görevler"), quests: specialQuests, closeAction: { withAnimation { showSpecialQuest = false } }, geo: geometry)
                            .transition(.move(edge: .trailing))
                            .zIndex(1)
                    } else {
                        mainMenu
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            .zIndex(0)
                    }
                }
                .padding(LayoutConfig.padding)
                .frame(
                    width: min(geometry.size.width * LayoutConfig.popupWidthRatio, 500),
                    height: min(geometry.size.height * LayoutConfig.popupHeightRatio, 800)
                )
                .background(.brown.opacity(0.95))
                .cornerRadius(LayoutConfig.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConfig.cornerRadius)
                        .stroke(Color("brown300"), lineWidth: 4)
                )
                .shadow(radius: 20)
                .overlay(alignment: .topTrailing) {
                    closeButton
                }
            }
        }
    }
    
    var closeButton: some View {
        Button {
            withAnimation {
                if isAnySubMenuOpen {
                    showDailyQuest = false
                    showWeeklyQuest = false
                    showMonthlyQuest = false
                    showSpecialQuest = false
                } else {
                    showQuest = false
                }
            }
        } label: {
            Image("close_button")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .offset(x: 12, y: -12)
        }
    }
    
    @ViewBuilder
    func questListView(title: String, quests: [QuestModel]?, closeAction: @escaping () -> Void, geo: GeometryProxy) -> some View {
        VStack {
            ZStack {
                Image("title_header").resizable().scaledToFit().frame(height: 50)
                Text(LocalizedStringKey(title))
                    .foregroundStyle(.white)
                    .font(.system(size: 20, weight: .bold))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 1, y: 1)
            }
            .padding(.bottom)
            
            if let list = quests, !list.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(list, id: \.self) { quest in
                            QuestRow(onQuestSelect: { model in selectQuest(model)}, onRewardClaim: { model in
                                claimReward(model)
                            }, quest: quest)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("No quests available.")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.headline)
                }
                Spacer()
            }
            
            Button(action: closeAction) {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Return back")
                }
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.brown.opacity(0.8))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
            }
            .padding(.top)
        }
    }
    
    var mainMenu: some View {
        VStack(spacing: 20) {
            ZStack {
                if let _ = UIImage(named: "title_header") {
                    Image("title_header").resizable().scaledToFit().frame(height: 60)
                }
                Text("Quests")
                    .foregroundStyle(.white)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 2)
            }
            .padding(.bottom, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(Constant.questTypeList, id: \.self) { model in
                        let hasReward = hasClaimableReward(for: model)
                        Button {
                            withAnimation(.spring()) {
                                switch model {
                                case .daily: showDailyQuest = true
                                case .weekly: showWeeklyQuest = true
                                case .monthly: showMonthlyQuest = true
                                case .special: showSpecialQuest = true
                                }
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(hasReward ? Color.green.opacity(0.2) : Color.white.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Image(model.imageIconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 35, height: 35)
                                        .shadow(radius: 2)
                                }
                                
                                Text(LocalizedStringKey(model.localizedTitle))
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(model.backgroundColor.opacity(0.9))
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func hasClaimableReward(for type: QuestType) -> Bool {
        let list: [QuestModel]?
        
        switch type {
        case .daily: list = dailyQuests
        case .weekly: list = weeklyQuests
        case .monthly: list = monthlyQuests
        case .special: list = specialQuests
        }
        
        return list?.contains(where: { $0.status == .completed }) ?? false
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

#Preview {
    @State var show = true
    
    let dummyQuest = QuestModel(
        id: UUID(),
        type: .daily,
        title: "Test Quest",
        description: "Deneme açıklaması",
        reward: .water(count: 100),
        status: .claimed,
        targetCount: 5,
        currentProgressCount: 2,
        questionType: .competitive,
        battleEnemyModel: .fireElemental,
        gameLevel: .easy
    )
    
    ForestQuestUI(
        showQuest: $show, selectQuest: { model in },
        dailyQuests: [dummyQuest, dummyQuest],
        weeklyQuests: [],
        monthlyQuests: [],
        specialQuests: [],
        claimReward: { _ in }
    )
}
