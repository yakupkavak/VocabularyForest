//
//  ForestQuestUI.swift
//  VocabularyForest
//

import SwiftUI

// MARK: - Constants

private extension ForestQuestUI {
    enum Constant {
        static let questTypeList: [QuestType] = [.daily, .weekly, .monthly, .special]
    }
}

private enum LayoutConfig {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16
    static let popupWidthRatio: CGFloat = 0.85
    static let popupHeightRatio: CGFloat = 0.70
}

private enum ForestQuestSection: Hashable {
    case daily
    case weekly
    case monthly
    case special

    var title: LocalizedStringKey {
        switch self {
        case .daily: "Günlük Görevler"
        case .weekly: "Haftalık Görevler"
        case .monthly: "Aylık Görevler"
        case .special: "Özel Görevler"
        }
    }

    var questType: QuestType {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .special: .special
        }
    }

    init?(questType: QuestType) {
        switch questType {
        case .daily: self = .daily
        case .weekly: self = .weekly
        case .monthly: self = .monthly
        case .special: self = .special
        }
    }
}

// MARK: - Helpers

private enum QuestRewardSizing {
    static func waterDropSize(count: Int, minCount: CGFloat = 3, maxCount: CGFloat = 25, minSize: CGFloat, maxSize: CGFloat) -> CGFloat {
        let safeCount = CGFloat(min(max(count, Int(minCount)), Int(maxCount)))
        let percentage = (safeCount - minCount) / (maxCount - minCount)
        return minSize + ((maxSize - minSize) * percentage)
    }
}

// MARK: - Progress Bar

struct QuestProgressBar: View {
    let current: Int
    let target: Int
    var color: Color = .green

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Progress")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text("\(current)/\(target)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.2))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .frame(height: 12)
        }
        .a11yGroup()
    }
}

// MARK: - Reward View

struct QuestRewardView: View {
    let reward: LocalRewardModel

    @ScaledMetric private var iconSize: CGFloat = 35
    @ScaledMetric private var backgroundSize: CGFloat = 50
    @ScaledMetric private var smallIconSize: CGFloat = 24

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow.opacity(0.6), .orange],
                            center: .center,
                            startRadius: 2,
                            endRadius: 30
                        )
                    )
                    .frame(width: backgroundSize, height: backgroundSize)
                    .shadow(radius: 2)

                switch reward.reward {
                    case .chest(let chest):
                    RewardImageView(asset: chest.closeLocalImagePath)
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .shadow(radius: 2)
                    case .standart(let rewardModel):
                    switch rewardModel.category {
                    case .animal, .plant, .sculpture:
                        RewardImageView(asset: rewardModel.posterImage)
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .shadow(radius: 2)

                    case .water:
                        Image("water_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: QuestRewardSizing.waterDropSize(
                                    count: reward.rewardCount,
                                    minSize: 18,
                                    maxSize: 36
                                ),
                                height: QuestRewardSizing.waterDropSize(
                                    count: reward.rewardCount,
                                    minSize: 18,
                                    maxSize: 36
                                )
                            )
                            .foregroundStyle(.blue)

                    case .gold:
                        Image("gold_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: smallIconSize, height: smallIconSize)
                            .foregroundStyle(.yellow)
                    case .diamond:
                        Image("diamond_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: smallIconSize, height: smallIconSize)
                    }
                }
            }

            VStack(alignment: .leading) {
                Text("Reward")
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(.white.opacity(0.8))
                switch reward.reward {
                    case .chest(let chest):
                    RewardImageView(asset: chest.closeLocalImagePath)
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .shadow(radius: 2)
                    case .standart(let rewardModel):
                    switch rewardModel.category {
                    case .animal, .plant, .sculpture:
                        Text(rewardModel.displayName.localized)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    case .water:
                        Text(String(localized: "\(reward.rewardCount) Water Drops"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    case .gold:
                        Text("\(reward.rewardCount) Gold")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    case .diamond:
                        Text("\(reward.rewardCount) Diamond")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.3))
        .cornerRadius(12)
        .a11yGroup()
    }
}

// MARK: - Info Badge

private struct QuestInfoBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            Text(LocalizedStringKey(value))
                .font(.caption)
                .bold()
                .foregroundStyle(color)
        }
        .a11yGroup()
    }
}

// MARK: - Quest Row Action View

private struct QuestRowActionView: View {
    let quest: QuestModel
    let onQuestSelect: (QuestModel) -> Void
    let onRewardClaim: (QuestModel) -> Void

    var body: some View {
        VStack(spacing: 12) {
            QuestRewardView(reward: quest.reward)

            Button {
                onQuestSelect(quest)
            } label: {
                Text("Göreve git")
                    .foregroundStyle(Color.clickableText)
            }

            switch quest.status {
            case .completed:
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

            case .claimed, .active:
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

            case .locked:
                EmptyView()
            }
        }
    }
}

// MARK: - Quest Row

struct QuestRow: View {
    let quest: QuestModel
    let isExpanded: Bool
    let onToggleExpansion: (String) -> Void
    let onQuestSelect: (QuestModel) -> Void
    let onRewardClaim: (QuestModel) -> Void

    @ScaledMetric private var iconBoxSize: CGFloat = 60

    private var statusColor: Color {
        switch quest.status {
        case .locked: .gray
        case .active: .yellow
        case .completed: .green
        case .claimed: .claimedText
        }
    }

    private var statusText: String {
        switch quest.status {
        case .locked: String(localized: "Locked")
        case .active: String(localized: "In Progress")
        case .completed: String(localized: "Completed!")
        case .claimed: String(localized: "Claimed")
        }
    }

    private var waterDropSize: CGFloat {
        QuestRewardSizing.waterDropSize(
            count: quest.reward.rewardCount,
            minSize: iconBoxSize * 0.3,
            maxSize: iconBoxSize * 0.6
        )
    }
    
    private var dynamicImageSize: CGFloat {
        return switch quest.reward.reward {
        case .chest(let chest):
            iconBoxSize * 0.7
        case .standart(let standart):
            switch standart.category {
            case .animal:
                iconBoxSize * 0.85
            case .plant:
                iconBoxSize * 0.85
            case .gold:
                iconBoxSize * 0.7
            case .water:
                waterDropSize
            case .diamond:
                iconBoxSize * 0.7
            case .sculpture:
                iconBoxSize * 0.85
            }
        }
    }


    var body: some View {
        VStack(spacing: 0) {
            Button {
                guard quest.status != .locked else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    onToggleExpansion(quest.id)
                }
            } label: {
                HStack(spacing: 14) {
                    iconView
                    contentView
                    Spacer()

                    if quest.status != .locked {
                        Image(systemName: "chevron.down")
                            .font(.title3.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .opacity(quest.status == .locked ? 0.6 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(quest.status == .locked)
            .accessibilityValue(String(localized: isExpanded ? "a11y_expanded" : "a11y_collapsed"))

            if isExpanded {
                detailView
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brown.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.2))
                .frame(width: iconBoxSize, height: iconBoxSize)
            RewardImageView(asset: quest.reward.reward.posterImage)
                .scaledToFit()
                .frame(maxWidth: dynamicImageSize, maxHeight: dynamicImageSize)
                .shadow(radius: 2)
            if quest.status == .locked {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    

    private var contentView: some View {
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
        }
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.2))

            HStack(alignment: .top) {
                Image(systemName: "scroll.fill")
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)

                Text(LocalizedStringKey(quest.description))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    QuestInfoBadge(
                        icon: "burst",
                        title: String(localized: "Enemy:"),
                        value: quest.battleEnemyModel.title.capitalized,
                        color: statusColor
                    )
                    .padding(.bottom, 1)

                    QuestInfoBadge(
                        icon: "brain.head.profile",
                        title: String(localized: "Mode:"),
                        value: quest.questionType.title.firstCapitalized,
                        color: statusColor
                    )
                }

                Spacer()

                VStack(alignment: .trailing) {
                    QuestInfoBadge(
                        icon: "flag.fill",
                        title: String(localized: "Level:"),
                        value: quest.gameLevel.title.firstCapitalized,
                        color: statusColor
                    )

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

                QuestRowActionView(
                    quest: quest,
                    onQuestSelect: onQuestSelect,
                    onRewardClaim: onRewardClaim
                )

                Spacer()
            }
        }
    }
}

// MARK: - Section Header

private struct ForestQuestSectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        ZStack {
            Image("title_header")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
                .accessibilityHidden(true)

            Text(title)
                .foregroundStyle(.white)
                .font(.system(size: 20, weight: .bold))
                .shadow(color: .black.opacity(0.5), radius: 1, x: 1, y: 1)
        }
        .padding(.bottom)
    }
}

// MARK: - Empty State

private struct ForestQuestEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.4))
                .accessibilityHidden(true)

            Text("No quests available.")
                .foregroundStyle(.white.opacity(0.7))
                .font(.headline)
        }
    }
}

// MARK: - Main Menu Row

private struct ForestQuestMenuRow: View {
    let model: QuestType
    let hasReward: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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

                Image(systemName: "chevron.forward")
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

// MARK: - Content

struct ForestQuestUI: View {
    @Binding var showQuest: Bool

    let selectQuest: (QuestModel) -> Void
    let dailyQuests: [QuestModel]?
    let weeklyQuests: [QuestModel]?
    let monthlyQuests: [QuestModel]?
    let specialQuests: [QuestModel]?
    let claimReward: (QuestModel) -> Void

    @State private var selectedSection: ForestQuestSection?
    @State private var expandedQuestIDs: Set<String> = []

    private var isShowingSubMenu: Bool {
        selectedSection != nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showQuest = false
                        }
                    }

                ZStack {
                    if let selectedSection {
                        questListView(
                            section: selectedSection,
                            quests: quests(for: selectedSection)
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
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
        .trackScreen(.questList)
    }

    private var closeButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isShowingSubMenu {
                    selectedSection = nil
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
                .accessibilityLabel(String(localized: "a11y_close"))
        }
    }

    private var mainMenu: some View {
        VStack(spacing: 20) {
            ZStack {
                if UIImage(named: "title_header") != nil {
                    Image("title_header")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .accessibilityHidden(true)
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
                        ForestQuestMenuRow(
                            model: model,
                            hasReward: hasClaimableReward(for: model)
                        ) {
                            guard let section = ForestQuestSection(questType: model) else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                selectedSection = section
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private func questListView(section: ForestQuestSection, quests: [QuestModel]) -> some View {
        VStack {
            ForestQuestSectionHeader(title: section.title)

            if quests.isEmpty {
                Spacer()
                ForestQuestEmptyStateView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(quests, id: \.id) { quest in
                            QuestRow(
                                quest: quest,
                                isExpanded: expandedQuestIDs.contains(quest.id),
                                onToggleExpansion: toggleExpansion,
                                onQuestSelect: selectQuest,
                                onRewardClaim: claimReward
                            )
                            .id(quest.id)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .scrollIndicators(.hidden)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedSection = nil
                }
            } label: {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.top)
        }
    }

    private func toggleExpansion(for questID: String) {
        if expandedQuestIDs.contains(questID) {
            expandedQuestIDs.remove(questID)
        } else {
            expandedQuestIDs.insert(questID)
        }
    }

    private func quests(for section: ForestQuestSection) -> [QuestModel] {
        switch section {
        case .daily:
            dailyQuests ?? []
        case .weekly:
            weeklyQuests ?? []
        case .monthly:
            monthlyQuests ?? []
        case .special:
            specialQuests ?? []
        }
    }

    private func hasClaimableReward(for type: QuestType) -> Bool {
        let list: [QuestModel]

        switch type {
        case .daily:
            list = dailyQuests ?? []
        case .weekly:
            list = weeklyQuests ?? []
        case .monthly:
            list = monthlyQuests ?? []
        case .special:
            list = specialQuests ?? []
        }

        return list.contains(where: { $0.status == .completed })
    }
}

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    /*
    @State var show = true

    let dummyQuest = QuestModel(
        id: UUID(),
        type: .daily,
        title: "Test Quest",
        description: "Deneme açıklaması",
        reward: .water(count: 100),
        lastUpdatedDate: Date(),
        status: .claimed,
        targetCount: 5,
        currentProgressCount: 2,
        questionType: .competitive,
        battleEnemyModel: .fireElemental,
        gameLevel: .easy
    )
    let dummyQuest1 = QuestModel(
        id: UUID(),
        type: .daily,
        title: "Test Quest",
        description: "Deneme açıklaması",
        reward: .gold(count: 100),
        lastUpdatedDate: Date(),
        status: .claimed,
        targetCount: 5,
        currentProgressCount: 2,
        questionType: .competitive,
        battleEnemyModel: .fireElemental,
        gameLevel: .easy
    )
    let dummyQuest2 = QuestModel(
        id: UUID(),
        type: .daily,
        title: "Test Quest",
        description: "Deneme açıklaması",
        reward: .diamond(count: 100),
        lastUpdatedDate: Date(),
        status: .claimed,
        targetCount: 5,
        currentProgressCount: 2,
        questionType: .competitive,
        battleEnemyModel: .fireElemental,
        gameLevel: .easy
    )
    ForestQuestUI(
        showQuest: $show,
        selectQuest: { _ in },
        dailyQuests: [dummyQuest, dummyQuest1, dummyQuest2],
        weeklyQuests: [],
        monthlyQuests: [],
        specialQuests: [],
        claimReward: { _ in }
    )
     */
}
