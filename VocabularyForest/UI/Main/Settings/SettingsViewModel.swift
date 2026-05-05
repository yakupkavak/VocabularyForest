//
//  SettingsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.11.2025.
//

import CoreData
import UserNotifications
import Combine
import StoreKit
import AuthenticationServices

struct PolicyContent: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

enum AuthError: Error {
    case invalidCredantial
}

class SettingsViewModel: ObservableObject {
    
    // MARK: - DEPENDENCIES
    
    private let notificationManager: any NotificationManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let syncManager: ForestSyncManagerProtocol
    private let forestManager: ForestDataManagerProtocol
    private let playerManager: PlayerDataManagerProtocol
    
    // MARK: - PROPERTIES
    
    private var cancellables = Set<AnyCancellable>()
    @Published var sheetContent: PolicyContent? = nil
    @Published var notificationsEnabled: Bool = false
    @Published var userSignIn: Bool = false
    @Published var lastSyncDate: String = ""
    @Published var userHaveForestInFirebase: Bool = false
    @Published var firebaseForest: SafeForestModel? = nil
    @Published var userLocalForest: SafeForestModel? = nil
    @Published var showConflictError: Bool = false
    @Published var conflictErrorMsg: String = ""
    @Published var playerName: String = ""
    
    // MARK: - INIT
    
    init(
        notificationManager: any NotificationManagerProtocol,
        coreDataManager: CoreDataManagerProtocol,
        authManager: any AuthManagerProtocol,
        syncManager: ForestSyncManagerProtocol,
        forestManager: ForestDataManagerProtocol,
        playerManager: PlayerDataManagerProtocol
    ) {
        self.notificationManager = notificationManager
        self.coreDataManager = coreDataManager
        self.authManager = authManager
        self.syncManager = syncManager
        self.forestManager = forestManager
        self.playerManager = playerManager
        setupInit()
    }
    
    // MARK: - HELPERS
    
    func signInApple(auth: ASAuthorization){
        guard let appleIDCredentials = auth.credential as? ASAuthorizationAppleIDCredential else { return }
        Task {
            do {
                let result = try await authManager.appleAuth(appleIDCredentials, nonce: AppleSignInManager.nonce)
                if result != nil {
                    await checkUserForest()
                }
            } catch(let error) {
                print(error)
            }
        }
    }
    
    func signInGoogle(){
        Task {
            do {
                try await authManager.signInWithGoogle()
                await checkUserForest()
            }catch {
                print(error)
            }
        }
    }
    
    func updateUserName(name: String) {
        if playerManager.updatePlayerName(contextType: .main, name: name).status == .success {
            playerName = name
        }
    }
    
    func trySyncManuel() {
        Task {
            let result = await syncManager.manualSync()
            if let error = result.error {
                let errorMessage = error.localizedDescription
                self.showError(message: errorMessage)
            }
        }
    }
    
    func checkUserForest() async {
        let conflictCheck = await syncManager.checkHasConflictOnlyMetadata()
        if conflictCheck.status == .error {
            showError(message: String(localized: "Sunucu eşleştirilemedi"))
            return
        }
        if conflictCheck.status == .success, conflictCheck.data == false {
            // Firebase de boş, ormanın da sahibi yok. bağlayalım o zaman
            let safeCurrentForest = forestManager.fetchSafeForest(contextType: .main)
            if safeCurrentForest.data?.ownerId == nil {
                //Ormanın sahibi yok, firebase de datası da yok bunları bağla geç
                await syncManager.forceOverwriteCloud()
            }
            return
        }
        
        let fireForest = await syncManager.userHaveForest()
        let safeCurrentForest = forestManager.fetchSafeForest(contextType: .main)
        if fireForest.status == .success {
            if let forest = fireForest.data, safeCurrentForest.status == .success, let currentSafeForest = safeCurrentForest.data {
                // Forest conflict
                userHaveForestInFirebase = true
                firebaseForest = forest
                userLocalForest = currentSafeForest
            }else if let forest = fireForest.data {
                //Only firebase
                userHaveForestInFirebase = true
                firebaseForest = forest
            }else if safeCurrentForest.status == .success, let currentSafeForest = safeCurrentForest.data {
                // only local forest, connect it.
                let syncResult = await syncManager.forceOverwriteCloud()
            }
        }
    }
    
    func resolveForestConflict(keep source: ForestSource) {
        Task {
            let result: Resource<Bool>
            
            switch source {
            case .local:
                result = await syncManager.forceOverwriteCloud()
                
            case .cloud:
                if let cloudForest = self.firebaseForest {
                    result = await syncManager.downloadAndOverwriteLocal(with: cloudForest)
                } else {
                    self.showError(message: String(localized: "Bulut verisi bulunamadı. Lütfen tekrar deneyin."))
                    return
                }
            }
            
            switch result.status {
                case .success:
                    self.userHaveForestInFirebase = false
                    self.firebaseForest = nil
                    self.userLocalForest = nil
                case .error:
                    let fallbackMsg = String(localized: "Kayıt işlemi başarısız oldu. Lütfen tekrar deneyin.")
                    self.showError(message: fallbackMsg)
                case .loading:
                    print("")
            }
        }
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            self.conflictErrorMsg = message
            self.showConflictError = true
        }
    }
    
    func signOut() {
        do {
            try authManager.signOut()
        }catch {
            print(error)
        }
    }
    
    func handleNotificationToggleChange() {
        let currentStatus = notificationManager.notificationsEnabled
        Task {
            if currentStatus {
                await notificationManager.requestEnable()
            } else {
                await notificationManager.requestDisable()
            }
            await notificationManager.checkNotificationStatus()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                }
            }
            if let error = error {
                print("Bildirim izin hatası: \(error.localizedDescription)")
            }
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    func showTermsOfUse() {
        sheetContent = PolicyContent(
            title: "Terms & Conditions",
            text: """
            
            These terms and conditions apply to the Vocabulary Forest app (hereby referred to as "Application") for mobile devices that was created by Yakup Kavak (hereby referred to as "Service Provider") as a Free service.

            Upon downloading or utilizing the Application, you are automatically agreeing to the following terms. It is strongly advised that you thoroughly read and understand these terms prior to using the Application.

            Unauthorized copying, modification of the Application, any part of the Application, or our trademarks is strictly prohibited. Any attempts to extract the source code of the Application, translate the Application into other languages, or create derivative versions are not permitted. All trademarks, copyrights, database rights, and other intellectual property rights related to the Application remain the property of the Service Provider.

            The Service Provider is dedicated to ensuring that the Application is as beneficial and efficient as possible. As such, they reserve the right to modify the Application or charge for their services at any time and for any reason. The Service Provider assures you that any charges for the Application or its services will be clearly communicated to you.

            The Application stores and processes personal data that you have provided to the Service Provider in order to provide the Service. It is your responsibility to maintain the security of your phone and access to the Application. The Service Provider strongly advise against jailbreaking or rooting your phone, which involves removing software restrictions and limitations imposed by the official operating system of your device. Such actions could expose your phone to malware, viruses, malicious programs, compromise your phone's security features, and may result in the Application not functioning correctly or at all.

            Please note that the Application utilizes third-party services that have their own Terms and Conditions. Below are the links to the Terms and Conditions of the third-party service providers used by the Application:

            Google Analytics for Firebase
            Firebase Crashlytics

            Please be aware that the Service Provider does not assume responsibility for certain aspects. Some functions of the Application require an active internet connection, which can be Wi-Fi or provided by your mobile network provider. The Service Provider cannot be held responsible if the Application does not function at full capacity due to lack of access to Wi-Fi or if you have exhausted your data allowance.

            If you are using the application outside of a Wi-Fi area, please be aware that your mobile network provider's agreement terms still apply. Consequently, you may incur charges from your mobile provider for data usage during the connection to the application, or other third-party charges. By using the application, you accept responsibility for any such charges, including roaming data charges if you use the application outside of your home territory (i.e., region or country) without disabling data roaming. If you are not the bill payer for the device on which you are using the application, they assume that you have obtained permission from the bill payer.

            Similarly, the Service Provider cannot always assume responsibility for your usage of the application. For instance, it is your responsibility to ensure that your device remains charged. If your device runs out of battery and you are unable to access the Service, the Service Provider cannot be held responsible.

            In terms of the Service Provider's responsibility for your use of the application, it is important to note that while they strive to ensure that it is updated and accurate at all times, they do rely on third parties to provide information to them so that they can make it available to you. The Service Provider accepts no liability for any loss, direct or indirect, that you experience as a result of relying entirely on this functionality of the application.

            The Service Provider may wish to update the application at some point. The application is currently available as per the requirements for the operating system (and for any additional systems they decide to extend the availability of the application to) may change, and you will need to download the updates if you want to continue using the application. The Service Provider does not guarantee that it will always update the application so that it is relevant to you and/or compatible with the particular operating system version installed on your device. However, you agree to always accept updates to the application when offered to you. The Service Provider may also wish to cease providing the application and may terminate its use at any time without providing termination notice to you. Unless they inform you otherwise, upon any termination, (a) the rights and licenses granted to you in these terms will end; (b) you must cease using the application, and (if necessary) delete it from your device.

            Changes to These Terms and Conditions
            The Service Provider may periodically update their Terms and Conditions. Therefore, you are advised to review this page regularly for any changes. The Service Provider will notify you of any changes by posting the new Terms and Conditions on this page.

            These terms and conditions are effective as of 2025-11-05

            Contact Us
            If you have any questions or suggestions about the Terms and Conditions, please do not hesitate to contact the Service Provider at vocabularyforest@gmail.com.

            """
        )
    }
    
    func showPrivacyPolicy() {
        sheetContent = PolicyContent(
            title: "Privacy Policy",
            text: """
            
            This privacy policy applies to the Vocabulary Forest app (hereby referred to as "Application") for mobile devices that was created by Yakup Kavak (hereby referred to as "Service Provider") as a Free service. This service is intended for use "AS IS".

            Information Collection and Use
            The Application collects information when you download and use it. This information may include information such as

            Your device's Internet Protocol address (e.g. IP address)
            The pages of the Application that you visit, the time and date of your visit, the time spent on those pages
            The time spent on the Application
            The operating system you use on your mobile device

            The Application does not gather precise information about the location of your mobile device.

            The Service Provider may use the information you provided to contact you from time to time to provide you with important information, required notices and marketing promotions.

            For a better experience, while using the Application, the Service Provider may require you to provide us with certain personally identifiable information. The information that the Service Provider request will be retained by them and used as described in this privacy policy.

            Third Party Access
            Only aggregated, anonymized data is periodically transmitted to external services to aid the Service Provider in improving the Application and their service. The Service Provider may share your information with third parties in the ways that are described in this privacy statement.

            Please note that the Application utilizes third-party services that have their own Privacy Policy about handling data. Below are the links to the Privacy Policy of the third-party service providers used by the Application:

            Google Analytics for Firebase
            Firebase Crashlytics

            The Service Provider may disclose User Provided and Automatically Collected Information:

            as required by law, such as to comply with a subpoena, or similar legal process;
            when they believe in good faith that disclosure is necessary to protect their rights, protect your safety or the safety of others, investigate fraud, or respond to a government request;
            with their trusted services providers who work on their behalf, do not have an independent use of the information we disclose to them, and have agreed to adhere to the rules set forth in this privacy statement.

            Opt-Out Rights
            You can stop all collection of information by the Application easily by uninstalling it. You may use the standard uninstall processes as may be available as part of your mobile device or via the mobile application marketplace or network.

            Data Retention Policy
            The Service Provider will retain User Provided data for as long as you use the Application and for a reasonable time thereafter. If you'd like them to delete User Provided Data that you have provided via the Application, please contact them at vocabularyforest@gmail.com and they will respond in a reasonable time.

            Children
            The Service Provider does not use the Application to knowingly solicit data from or market to children under the age of 13.

            The Application does not address anyone under the age of 13. The Service Provider does not knowingly collect personally identifiable information from children under 13 years of age. In the case the Service Provider discover that a child under 13 has provided personal information, the Service Provider will immediately delete this from their servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact the Service Provider (vocabularyforest@gmail.com) so that they will be able to take the necessary actions.

            Security
            The Service Provider is concerned about safeguarding the confidentiality of your information. The Service Provider provides physical, electronic, and procedural safeguards to protect information the Service Provider processes and maintains.

            Changes
            This Privacy Policy may be updated from time to time for any reason. The Service Provider will notify you of any changes to the Privacy Policy by updating this page with the new Privacy Policy. You are advised to consult this Privacy Policy regularly for any changes, as continued use is deemed approval of all changes.

            This privacy policy is effective as of 2025-11-05

            Your Consent
            By using the Application, you are consenting to the processing of your information as set forth in this Privacy Policy now and as amended by us.

            Contact Us
            If you have any questions regarding privacy while using the Application, or have questions about the practices, please contact the Service Provider via email at vocabularyforest@gmail.com.
            
            
            """
        )
    }
    
    func deleteAllData() {
        coreDataManager.deleteEverything(contextType: .background)
    }
}

private extension SettingsViewModel {
    func setupInit() {
        setupPlayer()
        setupNotification()
        setupUserInit()
        setupSync()
    }
    
    func setupPlayer() {
        let player = self.playerManager.fetchSafePlayer(contextType: .main)
        if let player {
            playerName = player.name
        }
    }
    func setupNotification() {
        self.notificationsEnabled = self.notificationManager.notificationsEnabled
        self.notificationManager.objectWillChange
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.notificationsEnabled = self.notificationManager.notificationsEnabled
        }
        .store(in: &cancellables)
    }
    func setupUserInit() {
        self.userSignIn = self.authManager.isUserSignedIn
        self.authManager.isUserSignedInPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isSignedIn in
                guard let self = self else { return }
                self.userSignIn = isSignedIn
                if isSignedIn {
                    Task.detached { [weak self] in
                        await self?.checkUserForest()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func setupSync() {
        self.syncManager.lastSyncDatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] lastSyncTime in
                if let lastSyncTime {
                    self?.lastSyncDate = lastSyncTime.toFriendlyLocalizedString()
                }
            }
            .store(in: &cancellables)
    }
}
