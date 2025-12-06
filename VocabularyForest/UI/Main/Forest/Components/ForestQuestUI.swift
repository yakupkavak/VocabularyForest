//
//  ForestQuestUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.12.2025.
//

import SwiftUI

private extension ForestQuestUI {
    enum Constant {
        static let questTypeList: [QuestType] = [
            .daily, .weekly, .monthly, .special
        ]
    }
}

struct QuestRow: View {
    
    @State private var showDetail = false
    var quest: QuestModel
    
    var body: some View {
        VStack{
            Text(quest.title).foregroundStyle(.white)
            if showDetail {
                Divider().background(Color.white.opacity(0.5))
                Text("Quest Decription").foregroundStyle(.white)
                Text(quest.description).foregroundStyle(.white)
                Divider().background(Color.white.opacity(0.5))
                Text("Quest Rewards").foregroundStyle(.white)
                if quest.reward.typeName == "water" {
                    Text("You will get \(quest.reward.valueString) water drops.")
                }else {
                    Text("You will get \(quest.reward.valueString).").foregroundStyle(.white)
                }
                Divider().background(Color.white.opacity(0.5))
                Text("Your Progress").foregroundStyle(.white)
                //Text("You have to \(quest.)").foregroundStyle(.white)

            }
        }
    }
}

struct ForestQuestUI: View {
    
    // MARK: - PROPERTIES
    
    @State private var showDailyQuest = false
    @State private var showWeeklyQuest = false
    @State private var showMonthlyQuest = false
    @State private var showSpecialQuest = false
    @Binding var showQuest: Bool

    var body: some View {
        VStack {
            if showDailyQuest {
                ZStack {
                    Image("title_header").resizable().scaledToFit()
                    Text("Daily Quests").foregroundStyle(.white).font(.system(size: 24))
                }
                ForEach(Constant.questTypeList, id: \.self) { model in
                    settingsRow(model: SettingsModel<QuestType>(title: model.localizedTitle, icon: model.imageIconName, color: model.backgroundColor, type: model)).onTapGesture {
                        switch model {
                        case .daily:
                            showDailyQuest = true
                        case .weekly:
                            showWeeklyQuest = true
                        case .monthly:
                            showMonthlyQuest = true
                        case .special:
                            showSpecialQuest = true
                        }
                    }
                }
                Button  {
                    showDailyQuest = false
                } label: {
                    Text("Return back").foregroundStyle(.logoGreen).padding().background(Color.white.opacity(0.3)).borderRadius(borderColor: .logoGreen, cornerRadius: 16)
                }
            }else if showWeeklyQuest {
                ZStack {
                    Image("title_header").resizable().scaledToFit()
                    Text("WeeklyQuests").foregroundStyle(.white).font(.system(size: 24))
                }
                ForEach(Constant.questTypeList, id: \.self) { model in
                    settingsRow(model: SettingsModel<QuestType>(title: model.localizedTitle, icon: model.imageIconName, color: model.backgroundColor, type: model)).onTapGesture {
                        switch model {
                        case .daily:
                            showDailyQuest = true
                        case .weekly:
                            showWeeklyQuest = true
                        case .monthly:
                            showMonthlyQuest = true
                        case .special:
                            showSpecialQuest = true
                        }
                    }
                }
            }
            else if showMonthlyQuest {
                ZStack {
                    Image("title_header").resizable().scaledToFit()
                    Text("MonthlyQuests").foregroundStyle(.white).font(.system(size: 24))
                }
                ForEach(Constant.questTypeList, id: \.self) { model in
                    settingsRow(model: SettingsModel<QuestType>(title: model.localizedTitle, icon: model.imageIconName, color: model.backgroundColor, type: model)).onTapGesture {
                        switch model {
                        case .daily:
                            showDailyQuest = true
                        case .weekly:
                            showWeeklyQuest = true
                        case .monthly:
                            showMonthlyQuest = true
                        case .special:
                            showSpecialQuest = true
                        }
                    }
                }
            }
            else if showSpecialQuest {
                ZStack {
                    Image("title_header").resizable().scaledToFit()
                    Text("Special Quests").foregroundStyle(.white).font(.system(size: 24))
                }
                ForEach(Constant.questTypeList, id: \.self) { model in
                    settingsRow(model: SettingsModel<QuestType>(title: model.localizedTitle, icon: model.imageIconName, color: model.backgroundColor, type: model)).onTapGesture {
                        switch model {
                        case .daily:
                            showDailyQuest = true
                        case .weekly:
                            showWeeklyQuest = true
                        case .monthly:
                            showMonthlyQuest = true
                        case .special:
                            showSpecialQuest = true
                        }
                    }
                }
            }else {
                ZStack {
                    Image("title_header").resizable().scaledToFit()
                    Text("Quests").foregroundStyle(.white).font(.system(size: 24))
                }
                ForEach(Constant.questTypeList, id: \.self) { model in
                    settingsRow(model: SettingsModel<QuestType>(title: model.localizedTitle, icon: model.imageIconName, color: model.backgroundColor, type: model)).onTapGesture {
                        switch model {
                        case .daily:
                            showDailyQuest = true
                        case .weekly:
                            showWeeklyQuest = true
                        case .monthly:
                            showMonthlyQuest = true
                        case .special:
                            showSpecialQuest = true
                        }
                    }
                }
            }
        }.padding().background(.brown.opacity(0.8)).cornerRadius(16).zIndex(3.0).frame(width: UIScreen.main.bounds.width * 0.6)
            .overlay(alignment: .topTrailing) {
                Button {
                    showQuest = false
                } label: {
                    Image("close_button").resizable().frame(maxWidth: 36, maxHeight: 36)
                        .offset(x: 12, y: -12)
                }
            }
    }
}


#Preview {
    @State var show = true
    ForestQuestUI(showQuest: $show)
}
