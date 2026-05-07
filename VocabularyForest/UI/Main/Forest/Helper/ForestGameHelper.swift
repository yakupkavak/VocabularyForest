//
//  ForestGameHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.11.2025.
//

import Foundation

protocol ForestGameHelperProtocol {
    func initalizeDailyQuests() -> [QuestModel]
    func initalizeWeeklyQuests() -> [QuestModel]
    func initalizeMonthlyQuests() -> [QuestModel]
    func initalizeSpecialQuests() -> [QuestModel]
}

struct ForestGameHelper: ForestGameHelperProtocol {
    private static let remoteQuestLock = NSLock()
    private static var remoteQuestTemplatesByType: [QuestType: [QuestModel]] = [:]
    
    static func updateRemoteQuestTemplates(_ templates: [QuestModel]) {
        remoteQuestLock.lock()
        remoteQuestTemplatesByType = Dictionary(grouping: templates, by: { $0.type })
        remoteQuestLock.unlock()
    }
    
    static func clearRemoteQuestTemplates() {
        remoteQuestLock.lock()
        remoteQuestTemplatesByType = [:]
        remoteQuestLock.unlock()
    }
    
    private static func remoteTemplates(for type: QuestType) -> [QuestModel]? {
        remoteQuestLock.lock()
        let templates = remoteQuestTemplatesByType[type]
        remoteQuestLock.unlock()
        return templates
    }
    
    // MARK: - Daily Quests
    
    func initalizeDailyQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .daily), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return []
    }
    
    // MARK: - Weekly Quests
    
    func initalizeWeeklyQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .weekly), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return []
    }
    
    // MARK: - Monthly Quests
    
    func initalizeMonthlyQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .monthly), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return []
    }
    
    // MARK: - Special Quests
    
    func initalizeSpecialQuests() -> [QuestModel] {
        if let remoteTemplates = Self.remoteTemplates(for: .special), !remoteTemplates.isEmpty {
            return remoteTemplates
        }
        return []
    }
}
