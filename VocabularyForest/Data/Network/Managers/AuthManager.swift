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
    // MARK: INIT
    
    init() {
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
            print("Unable to fetch identity token")
            return nil
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return nil
        }
        let credentials = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: nonce,
                                                       fullName: appleIDCredential.fullName)
        do {
            return try await authenticateUser(credentials: credentials)
        }
        catch {
            print("FirebaseAuthError: appleAuth(appleIDCredential:nonce:) failed. \(error)")
            throw error
        }
    }
    
    func signOut() throws {
        if let currentUser {
            let providers = currentUser.providerData.map { $0.providerID }.joined(separator: ", ")
            if providers.contains("google.com") {
                signOutFromGoogle()
            }
            else {
                try auth.signOut()
            }
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
                        print("FirebaseAuthError: signOut() failed. \(error)")
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
            print("FirebaseAuthError: googleAuth(user:) failed. \(error)")
            throw error
        }
    }
    func setupCurrentUser(user: User) {
        currentUser = user
        isUserSignedIn = true
    }
}
