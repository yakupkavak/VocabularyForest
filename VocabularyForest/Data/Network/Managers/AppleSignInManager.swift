//
//  AppleSignInManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 8.04.2026.
//

import AuthenticationServices
import CryptoKit

class AppleSignInManager: NSObject {
    
    static let shared = AppleSignInManager()
    
    fileprivate static var currentNonce: String?
    private var credentialContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    static var nonce: String? {
        currentNonce ?? nil
    }

    private override init() {}

    func requestAppleAuthorization(_ request: ASAuthorizationAppleIDRequest) {
        AppleSignInManager.currentNonce = randomNonceString()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(AppleSignInManager.currentNonce!)
    }
    
    /// Hesap silme öncesi reauth + token revoke için taze Apple credential alır.
    @MainActor
    func requestFreshCredential() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            credentialContinuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            requestAppleAuthorization(request)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            credentialContinuation?.resume(returning: credential)
        } else {
            credentialContinuation?.resume(throwing: AuthError.invalidCredantial)
        }
        credentialContinuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        credentialContinuation?.resume(throwing: error)
        credentialContinuation = nil
    }
}

extension AppleSignInManager {
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }

        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
