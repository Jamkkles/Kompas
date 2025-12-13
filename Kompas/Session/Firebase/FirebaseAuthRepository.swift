import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import FirebaseStorage

@MainActor
final class FirebaseAuthRepository {
    static let shared = FirebaseAuthRepository()
    private init() {}

    // MARK: - Email/Password
    func register(name: String, email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let change = result.user.createProfileChangeRequest()
        change.displayName = name
        try? await change.commitChanges()
        return try await mapCurrentUser()
    }

    func login(email: String, password: String) async throws -> User {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
        return try await mapCurrentUser()
    }

    func me() async throws -> User {
        try await mapCurrentUser()
    }

    func logout() async throws {
        try Auth.auth().signOut()
    }

    // MARK: - Sign in with Apple
    func signInWithApple(anchor: ASPresentationAnchor) async throws -> User {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleAuthDelegate(nonce: nonce)
        controller.delegate = delegate
        controller.presentationContextProvider = AppleAuthPresentationProvider(anchor: anchor)

        return try await withCheckedThrowingContinuation { cont in
            // Swift 6: Result<User, any Error>
            delegate.completion = { result in
                cont.resume(with: result)
            }
            controller.performRequests()
        }
    }

    // MARK: - Sign in with Google
    func signInWithGoogle() async throws -> User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Falta clientID"])
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let topVC = UIApplication.shared.topViewController else {
            throw NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "No hay ViewController para presentar"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -3, userInfo: [NSLocalizedDescriptionKey: "No se obtuvo idToken"])
        }
        let accessToken = user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        _ = try await Auth.auth().signIn(with: credential)
        return try await mapCurrentUser()
    }

    func updateProfile(name: String, photoBase64: String?) async throws {
    guard let user = Auth.auth().currentUser else {
        throw NSError(domain: "FirebaseAuth", code: -10, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"])
    }

    let changeRequest = user.createProfileChangeRequest()
    changeRequest.displayName = name

    if let photoBase64 = photoBase64 {
        let storageRef = Storage.storage().reference().child("profile_pictures/\(user.uid).jpg")
        if let imageData = Data(base64Encoded: photoBase64) {
            do {
                _ = try await storageRef.putDataAsync(imageData)
                let downloadURL = try await storageRef.downloadURL()
                changeRequest.photoURL = downloadURL
            } catch {
                print("Error al subir la imagen a Firebase Storage: \(error.localizedDescription)")
                throw error
            }
        }
    }

    try await changeRequest.commitChanges()
}

    // MARK: - Helpers Apple
    private final class AppleAuthDelegate: NSObject, ASAuthorizationControllerDelegate {
        let nonce: String
        var completion: ((Result<User, any Error>) -> Void)?   // Swift 6

        init(nonce: String) { self.nonce = nonce }

        func authorizationController(controller: ASAuthorizationController,
                                     didCompleteWithAuthorization authorization: ASAuthorization) {
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = appleIDCredential.identityToken,
                  let idTokenString = String(data: idTokenData, encoding: .utf8) else {
                completion?(.failure(NSError(domain: "AppleSignIn", code: -1,
                                             userInfo: [NSLocalizedDescriptionKey:"No se obtuvo token de Apple"])))
                return
            }

            // 🔁 NUEVA API de FirebaseAuth para Apple
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    if result.user.displayName == nil {
                        let change = result.user.createProfileChangeRequest()
                        change.displayName = appleIDCredential.fullName?.givenName ?? "Usuario"
                        try? await change.commitChanges()
                    }
                    let mapped = try await FirebaseAuthRepository.shared.mapCurrentUser()
                    completion?(.success(mapped))
                } catch {
                    completion?(.failure(error))
                }
            }
        }


        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            completion?(.failure(error))
        }
    }

    private final class AppleAuthPresentationProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
        let anchor: ASPresentationAnchor
        init(anchor: ASPresentationAnchor) { self.anchor = anchor }
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor { anchor }
    }

    // MARK: - Current user mapper
    fileprivate func mapCurrentUser() async throws -> User {
        guard let u = Auth.auth().currentUser else {
            throw NSError(
                domain: "FirebaseAuth",
                code: -10,
                userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"]
            )
        }
        let name = u.displayName ?? u.email ?? "Usuario"
        return User(
            id: u.uid,
            email: u.email ?? "",
            name: name,
            photoURL: u.photoURL        // <- aquí queda lista para el mapa y el perfil
        )
    }
}
