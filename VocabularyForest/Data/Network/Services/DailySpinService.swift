//
//  DailySpinService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.06.2026.
//

import Combine
import Foundation
import YKSpinWheel
import SwiftUI

enum DailySpinServiceError: Error {
    case emptySpinList
    case emptySpinTrakcs
    case invalidSpinID
}

enum DailySpinReadyState {
    case claimable
    case alreadyClaimed(remainSeconds: TimeInterval)
}

protocol DailySpinServiceProtocol {
    var dailySpinListPublisher: AnyPublisher<[SpinModel], Never> { get }
    var dailySpinStatePublisher: AnyPublisher<DailySpinReadyState, Never> { get }
    var dailySpinList: [SpinModel] { get }
    var currentSpinState: DailySpinReadyState { get }
    
    func convertRemoteToDailySpinList(list: RemoteDailySpinListModel) async throws
    func checkAndUpdateSpinState() async
    func claimDailySpinReward() async throws
    func convertLocalReward(model: SpinModel) throws -> LocalRewardModel
}

final class DailySpinService {
    
    // MARK: - PROPERTIES
    
    private let forestManager: ForestDataManagerProtocol
    private let rewardRepository: RewardRepositoryProtocol
    private var activeSpinRewardList: [Int: LocalRewardModel] = [:]
    @Published private var activeSpinList: [SpinModel] = []
    @Published private var dailySpinState: DailySpinReadyState = .claimable
    
    private var stateUpdateTask: Task<Void, Never>?
    
    // MARK: - INIT
    
    init(forestManager: ForestDataManagerProtocol, rewardRepository: RewardRepositoryProtocol) {
        self.forestManager = forestManager
        self.rewardRepository = rewardRepository
    }
    
}

extension DailySpinService: DailySpinServiceProtocol {
    
    var dailySpinListPublisher: AnyPublisher<[SpinModel], Never> {
        $activeSpinList.eraseToAnyPublisher()
    }
    
    var dailySpinStatePublisher: AnyPublisher<DailySpinReadyState, Never> {
        $dailySpinState.eraseToAnyPublisher()
    }
    
    var dailySpinList: [SpinModel] {
        activeSpinList
    }
    
    var currentSpinState: DailySpinReadyState {
        dailySpinState
    }
    
    func convertLocalReward(model: SpinModel) throws -> LocalRewardModel {
        guard let reward = activeSpinRewardList[model.id] else { throw DailySpinServiceError.invalidSpinID }
        return reward
    }
     
    func convertRemoteToDailySpinList(list: RemoteDailySpinListModel) async throws {
        guard let models = list.items else { throw DailySpinServiceError.emptySpinList }
        
        for model in models {
            guard let id = model.id, let weight = model.weight, let reward = model.reward else { return }
            var localReward: LocalRewardModel
            do {
                localReward = try await rewardRepository.processAndGetLocalReward(from: reward)
            } catch {
                throw RewardRepositoryError.decodingError
            }
            //let dailyModel = DailySpinModel(id: id, weight: weight, reward: localReward, textColorHex: model.textColorHex, backgroundHexes: model.backgroundHexes)
            let customImage = RewardImageView(asset: localReward.reward.posterImage).frame(
                width: UIScreen.main.bounds.height * 0.05,
                height: UIScreen.main.bounds.height * 0.05
            )
            
            var spinModel: SpinModel
            
            if let textColor = model.textColorHex, let backgroundHexes = model.backgroundHexes {
                spinModel = SpinModel(
                    id: id,
                    text: model.text?.localized ?? "",
                    customImage: customImage,
                    weight: weight,
                    textColor: textColor.color,
                    background: makeGradient(hexes: backgroundHexes)
                )
            }else {
                spinModel = SpinModel(
                    id: id,
                    text: model.text?.localized ?? "",
                    customImage: customImage,
                    weight: weight
                )
            }
                
            activeSpinList.append(spinModel)
            activeSpinRewardList[id] = localReward
        }
         
    }
    
    func makeGradient(hexes: [String]) -> LinearGradient {
        let colors = hexes.map { $0.color }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func checkAndUpdateSpinState() async {
        stateUpdateTask?.cancel()
        
        do {
            let trueNow = try await NetworkTimeHelper.getTrueTime()
            updateSpinState(now: trueNow)
        } catch {
            /// Offline fallback: keep the lock with local time instead of failing open
            updateSpinState(now: Date())
        }
    }
    
    func claimDailySpinReward() async throws {
        let trueNow = try await NetworkTimeHelper.getTrueTime()
        try forestManager.updateDailySpinTime(time: trueNow, contextType: .main)
        await checkAndUpdateSpinState()
    }
}

private extension DailySpinService {
    
    func fetchDailySpinTargetDate() -> Date? {
        let localForestRes = forestManager.fetchSafeForest(contextType: .main)
        guard let forest = localForestRes.data, let lastUsed = forest.dailyActivities.dailySpinLastUsedDate else { return nil }
        return lastUsed.addingTimeInterval(86400)
    }
    
    func updateSpinState(now: Date) {
        if let targetDate = fetchDailySpinTargetDate(), targetDate > now {
            let remainSeconds = targetDate.timeIntervalSince(now)
            DispatchQueue.main.async {
                self.dailySpinState = .alreadyClaimed(remainSeconds: remainSeconds)
            }
            scheduleStateUpdate(after: remainSeconds)
        } else {
            DispatchQueue.main.async {
                self.dailySpinState = .claimable
            }
        }
    }
    
    func scheduleStateUpdate(after seconds: TimeInterval) {
        stateUpdateTask = Task {
            let nanoseconds = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            
            DispatchQueue.main.async {
                self.dailySpinState = .claimable
            }
        }
    }
}
