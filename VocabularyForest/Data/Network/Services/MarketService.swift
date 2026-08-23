//
//  MarketService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.07.2026.
//

import Combine
import Foundation

enum MarketServiceError: LocalizedError {
    case emptyMarketList
    case insufficientGold
    case insufficientDiamond
    case emptyForestData
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyMarketList:
            return String(localized: "Market is not available right now.")
        case .insufficientGold:
            return String(localized: "You don't have enough gold.")
        case .insufficientDiamond:
            return String(localized: "You don't have enough diamonds.")
        case .emptyForestData:
            return String(localized: "Local forest data is not available.")
        case .purchaseFailed:
            return String(localized: "Purchase could not be completed. Please try again.")
        }
    }
}

protocol MarketServiceProtocol {
    var marketScreenModelPublisher: AnyPublisher<MarketScreenModel?, Never> { get }
    var marketScreenModel: MarketScreenModel? { get }
    
    func convertRemoteToMarketList(list: RemoteMarketListModel) async throws
    func purchaseItem(item: MarketItemModel) async throws
}

final class MarketService {
    
    // MARK: - PROPERTIES
    
    private let forestManager: ForestDataManagerProtocol
    private let rewardRepository: RewardRepositoryProtocol
    @Published private var screenModel: MarketScreenModel?
    
    // MARK: - INIT
    
    init(forestManager: ForestDataManagerProtocol, rewardRepository: RewardRepositoryProtocol) {
        self.forestManager = forestManager
        self.rewardRepository = rewardRepository
    }
}

extension MarketService: MarketServiceProtocol {
    
    var marketScreenModelPublisher: AnyPublisher<MarketScreenModel?, Never> {
        $screenModel.eraseToAnyPublisher()
    }
    
    var marketScreenModel: MarketScreenModel? {
        screenModel
    }
    
    func convertRemoteToMarketList(list: RemoteMarketListModel) async throws {
        guard let remoteSections = list.sections, !remoteSections.isEmpty else {
            throw MarketServiceError.emptyMarketList
        }
        
        var sections: [MarketSectionModel] = []
        
        for remoteSection in remoteSections {
            guard let sectionID = remoteSection.id, let remoteItems = remoteSection.items else { continue }
            
            var items: [MarketItemModel] = []
            
            for remoteItem in remoteItems {
                guard let itemID = remoteItem.id,
                      let currencyValue = remoteItem.price?.currency,
                      let currency = MarketCurrency.convertCurrency(value: currencyValue),
                      let amount = remoteItem.price?.amount,
                      let remoteReward = remoteItem.reward else { continue }
                
                var localReward: LocalRewardModel
                do {
                    localReward = try await rewardRepository.processAndGetLocalReward(from: remoteReward)
                } catch {
                    throw RewardRepositoryError.decodingError
                }
                
                items.append(
                    MarketItemModel(
                        id: itemID,
                        price: MarketPriceModel(currency: currency, amount: amount),
                        reward: localReward
                    )
                )
            }
            
            guard !items.isEmpty else { continue }
            
            sections.append(
                MarketSectionModel(
                    id: sectionID,
                    title: remoteSection.title?.localized ?? "",
                    items: items
                )
            )
        }
        
        guard !sections.isEmpty else { throw MarketServiceError.emptyMarketList }
        
        let model = MarketScreenModel(
            title: list.title?.localized ?? String(
                localized: "market_title",
                defaultValue: "Market",
                comment: "Main title of the Market screen"
            ),
            sections: sections
        )
        
        DispatchQueue.main.async {
            self.screenModel = model
        }
    }
    
    func purchaseItem(item: MarketItemModel) async throws {
        guard let forest = forestManager.fetchSafeForest(contextType: .main).data else {
            throw MarketServiceError.emptyForestData
        }
        
        switch item.price.currency {
        case .gold:
            guard forest.moneyValue >= item.price.amount else {
                throw MarketServiceError.insufficientGold
            }
            let result = forestManager.updateMoneyValue(money: -item.price.amount, contextType: .main)
            guard result.status == .success else {
                throw result.error ?? MarketServiceError.purchaseFailed
            }
        case .diamond:
            guard forest.diamondValue >= item.price.amount else {
                throw MarketServiceError.insufficientDiamond
            }
            let result = forestManager.updateDiamondValue(diamond: -item.price.amount, contextType: .main)
            guard result.status == .success else {
                throw result.error ?? MarketServiceError.purchaseFailed
            }
        }
    }
}
