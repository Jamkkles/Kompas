import Foundation
import AuthenticationServices

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()          // <- requerido

    @Published var user: User?                  // <- requerido
    @Published var isAuthenticated = false      // <- requerido
    @Published var errorMessage: String?        // <- requerido

    private init() {}

    func bootstrap() async {
        do {
            let me = try? await FirebaseAuthRepository.shared.me()
            self.user = me
            self.isAuthenticated = (me != nil)
        }
    }

    func register(name: String, email: String, password: String) async {
        do {
            let u = try await FirebaseAuthRepository.shared.register(name: name, email: email, password: password)
            self.user = u; self.isAuthenticated = true; self.errorMessage = nil
        } catch { self.errorMessage = error.localizedDescription }
    }

    func login(email: String, password: String) async {
        do {
            let u = try await FirebaseAuthRepository.shared.login(email: email, password: password)
            self.user = u; self.isAuthenticated = true; self.errorMessage = nil
        } catch { self.errorMessage = error.localizedDescription }
    }

    func logout() async {
        do { try await FirebaseAuthRepository.shared.logout() } catch {
            self.errorMessage = error.localizedDescription
        }
        self.user = nil; self.isAuthenticated = false
    }

    // Social
    func signInWithApple(anchor: ASPresentationAnchor) async {
        do {
            let u = try await FirebaseAuthRepository.shared.signInWithApple(anchor: anchor)
            self.user = u; self.isAuthenticated = true; self.errorMessage = nil
        } catch { self.errorMessage = error.localizedDescription }
    }

    func signInWithGoogle() async {
        do {
            let u = try await FirebaseAuthRepository.shared.signInWithGoogle()
            self.user = u; self.isAuthenticated = true; self.errorMessage = nil
        } catch { self.errorMessage = error.localizedDescription }
    }
}
