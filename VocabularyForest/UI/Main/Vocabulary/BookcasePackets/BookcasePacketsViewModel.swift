//
//  BookcasePacketsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.12.2025.
//

import Combine
import Foundation
import CoreAPI
import DTO
import GoogleMobileAds
import UIKit

enum UIState {
    case success
    case loading
    case empty
    case error(String)
}

enum DownloadState: Equatable {
    case waiting
    case downloading
    case success
    case addWaiting
    case error(String)
}

protocol BookcasePacketsViewModelProtocol: ObservableObject, FullScreenContentDelegate {
    var libraries: Libraries? { get }
    var selectedLibrary: String? { get }
    var uiState: UIState { get }
    var downloadState: DownloadState { get }
    
    func selectLibrary(code: String)
    func refreshData()
    func downloadLibrary(model: Library)
    func loadRewardedAd()
    func showAdAndDownload(from rootViewController: UIViewController, library: Library)
}

class BookcasePacketsViewModel: NSObject, BookcasePacketsViewModelProtocol {

    // MARK: - PROPERTIES

    @Published var libraries: Libraries? =  nil
    @Published var selectedLibrary: String? = nil
    @Published var uiState: UIState = .loading
    @Published var downloadState: DownloadState = .waiting
    
    let networkService: APIServiceProtocol
    let coreDataService: CoreDataManagerProtocol
    private let analyticsService: AnalyticsServiceProtocol

    private var rewardedAd: RewardedAd?

    // MARK: - INIT

    init(networkService: APIServiceProtocol, dataManager: CoreDataManagerProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.networkService = networkService
        self.coreDataService = dataManager
        self.analyticsService = analyticsService
        super.init()

        refreshData()
    }
    
    // MARK: - HELPERS
    
    func selectLibrary(code: String) {
        selectedLibrary = code
    }
    
    func refreshData() {
        networkService.fetchLibraries { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                if let libraries = data.libraries {
                    if libraries.isEmpty {
                        self.uiState = .empty
                    } else {
                        self.libraries = data
                        self.selectedLibrary = data.libraries?.first?.sourceLanguage
                        self.uiState = .success
                    }
                }
            case .failure(let error):
                self.uiState = .error(error.message)
            }
        }
    }
    
    func downloadLibrary(model: Library) {
        downloadLibrary(model: model, unlockMethod: .free)
    }
    
    // MARK: - PRIVATE HELPERS

    private func downloadLibrary(model: Library, unlockMethod: PacketUnlockMethod) {
        downloadState = .downloading
        guard let path = model.id else {
            downloadState = .error(String(localized: "Kitaplık bulunamadı"))
            return
        }
        analyticsService.log(.packetDownloadStarted(packetID: path, unlockMethod: unlockMethod))
        networkService.fetchBookcaseRequest(values: GetBookcaseRequestModel(bookcaseID: path)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let requestResult):
                coreDataService.importBookcase(requestResult, overwrite: true, contextType: .background) { result in
                    switch result {
                    case .success(_):
                        self.downloadState = .success
                        self.analyticsService.log(.packetDownloadCompleted(
                            packetID: path,
                            wordCount: requestResult.wordCount ?? requestResult.words?.count ?? 0
                        ))
                        self.analyticsService.log(.bookcaseCreated(
                            languagePair: "\(requestResult.sourceLanguage ?? "")_\(requestResult.targetLanguage ?? "")",
                            source: .packet
                        ))
                    case .failure(let failure):
                        switch failure {
                        case .alreadyExist:
                            self.downloadState = .error("Bu isim kullanılıyor. İsmini değiştir ya da silmelisin")
                            self.analyticsService.log(.packetDownloadFailed(packetID: path, reason: AnalyticsFailureReason.alreadyExist))
                        case .missingRequiredFields:
                            self.downloadState = .error("Bilinmeyen bir hata oluştu")
                            self.analyticsService.log(.packetDownloadFailed(packetID: path, reason: AnalyticsFailureReason.missingFields))
                        }
                    }
                }
            case .failure(let error):
                downloadState = .error(error.message)
                analyticsService.log(.packetDownloadFailed(packetID: path, reason: AnalyticsFailureReason.network))
            }
        }
    }

    // MARK: - ADMOB HELPERS
    
    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: AppConfig.rewardedAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                uiState = .error(String(localized: "Reklam yüklenirken hata oluştu. Birazdan tekrar deneyiniz"))
                return
            }
            Task { @MainActor in
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    func showAdAndDownload(from rootViewController: UIViewController, library: Library) {
        if let ad = rewardedAd {
            ad.present(from: rootViewController) {
                self.downloadLibrary(model: library, unlockMethod: .rewardedAd)
            }
        } else {
            uiState = .error(String(localized: "Reklam henüz hazır değil."))
            downloadState = .addWaiting
            loadRewardedAd()
        }
    }
}

// MARK: - GADFullScreenContentDelegate

extension BookcasePacketsViewModel: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        downloadState = .error(String(localized: "Reklam esnasında hata oluştu"))
        loadRewardedAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        downloadState = .waiting
        loadRewardedAd()
    }
}
