//
//  AuthManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.04.2026.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import Combine

// MARK: - AuthManager PROTOCOL

protocol AuthManagerProtocol: ObservableObject {
    var isUserSignedInPublisher: AnyPublisher<Bool, Never> { get }
    var isUserSignedIn: Bool { get }
    func appleAuth(_ appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?) async throws -> AuthDataResult?
    func signInWithGoogle() async throws
    func signOut() throws
    func deleteAccount(cloudCleanup: () async throws -> Void) async throws
}

enum SignInType {
    case google
    case apple
}

// MARK: - MANAGER

class AuthManager: AuthManagerProtocol {
    
    // MARK: - PROPERTIES
    
    private let auth = Auth.auth()
    private var currentUser: User? = nil
    @Published var isUserSignedIn: Bool = false
    var isUserSignedInPublisher: AnyPublisher<Bool, Never> {
        $isUserSignedIn.eraseToAnyPublisher()
    }
    private let logger: AppLoggerProtocol

    // MARK: INIT

    init(logger: AppLoggerProtocol = AppLogger.shared) {
        self.logger = logger
        checkPreviousSign()
        verifySignInWithAppleID()
    }
    
    // MARK: - GOOGLE SIGN
    
    func signInWithGoogle() async throws {
        do {
            guard let user = try await signInWithGoogle() else { return }

            let result = try await googleAuth(user)
            if let result = result, let authUser = Auth.auth().currentUser {
                
                setupCurrentUser(user: authUser)
            }
        }
        catch {
            throw error
        }
    }
    
    // MARK: - APPLE SIGN
    
    func appleAuth(
        _ appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?
    ) async throws -> AuthDataResult? {
        guard let nonce = nonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            logger.error("Apple sign-in could not fetch the identity token", category: .auth)
            return nil
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            logger.error("Apple sign-in could not serialize the identity token", category: .auth)
            return nil
        }
        let credentials = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: nonce,
                                                       fullName: appleIDCredential.fullName)
        do {
            return try await authenticateUser(credentials: credentials)
        }
        catch {
            logger.error("Apple authentication failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }
    
    func signOut() throws {
        let providers = auth.currentUser?.providerData.map { $0.providerID } ?? []
        if providers.contains("google.com") {
            signOutFromGoogle()
        }
        try auth.signOut()
        currentUser = nil
        isUserSignedIn = false
    }
    
    // MARK: - DELETE ACCOUNT
    
    /// Apple 5.1.1(v): reauth -> wipe cloud data -> revoke the Apple token -> delete the account.
    func deleteAccount(cloudCleanup: () async throws -> Void) async throws {
        guard let user = auth.currentUser else { return }
        let providers = user.providerData.map { $0.providerID }
        
        if providers.contains("apple.com") {
            let appleCredential = try await AppleSignInManager.shared.requestFreshCredential()
            guard let tokenData = appleCredential.identityToken,
                  let idTokenString = String(data: tokenData, encoding: .utf8) else {
                throw AuthError.invalidCredantial
            }
            let credentials = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                            rawNonce: AppleSignInManager.nonce,
                                                            fullName: nil)
            try await user.reauthenticate(with: credentials)
            try await cloudCleanup()
            if let codeData = appleCredential.authorizationCode,
               let authCode = String(data: codeData, encoding: .utf8) {
                try await auth.revokeToken(withAuthorizationCode: authCode)
            }
        }
        else {
            if let googleUser = try await signInWithGoogle(), let idToken = googleUser.idToken?.tokenString {
                let credentials = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                accessToken: googleUser.accessToken.tokenString)
                try await user.reauthenticate(with: credentials)
            }
            try await cloudCleanup()
            signOutFromGoogle()
        }
        
        try await user.delete()
        await MainActor.run {
            currentUser = nil
            isUserSignedIn = false
        }
    }
}

private extension AuthManager {
    func authenticateUser(credentials: AuthCredential) async throws -> AuthDataResult? {
        return try await Auth.auth().signIn(with: credentials)
    }
    func checkPreviousSign() {
        let _ = auth.addStateDidChangeListener { [weak self] auth, user in
            guard let self else { return }
            DispatchQueue.main.async{
                if let user {
                    self.setupCurrentUser(user: user)
                } else {
                    self.currentUser = nil
                    self.isUserSignedIn = false
                }
            }
        }
    }
    func verifySignInWithAppleID() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                switch credentialState {
                case .authorized:
                    break
                case .revoked, .notFound:
                    do {
                        try self.signOut()
                    }
                    catch {
                        self.logger.error("Sign-out after revoked Apple credential failed: \(error.localizedDescription)", category: .auth)
                    }
                default:
                    break
                }
            }
        }
    }
    
    func signOutFromGoogle() {
        GIDSignIn.sharedInstance.signOut()
    }
    @MainActor
    func signInWithGoogle() async throws -> GIDGoogleUser? {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            return try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        } else {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return nil }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            return result.user
        }
    }
    
    func googleAuth(_ user: GIDGoogleUser) async throws -> AuthDataResult? {
        guard let idToken = user.idToken?.tokenString else { return nil }
        
        let credentials = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        do {
            return try await authenticateUser(credentials: credentials)
        }
        catch {
            logger.error("Google authentication failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }
    func setupCurrentUser(user: User) {
        currentUser = user
        isUserSignedIn = true
    }
}
