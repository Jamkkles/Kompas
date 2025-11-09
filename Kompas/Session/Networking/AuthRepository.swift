import Foundation

@MainActor
final class AuthRepository {
    static let shared = AuthRepository()
    private let api = APIClient.shared

    private init() {
        api.tokenProvider = { TokenStorage.shared.read(.access) }
        api.refreshAction = { try await self.refresh() }
    }

    func register(name: String, email: String, password: String) async throws -> User {
        let req = AuthRegisterRequest(email: email, password: password, name: name)
        let env: AuthUserEnvelope = try await api.request("/auth/register", method: "POST", body: req)
        persist(env.tokens)
        return env.user
    }

    func login(email: String, password: String) async throws -> User {
        let req = AuthLoginRequest(email: email, password: password)
        let env: AuthUserEnvelope = try await api.request("/auth/login", method: "POST", body: req)
        persist(env.tokens)
        return env.user
    }

    func me() async throws -> User {
        try await api.request("/me", authorized: true)
    }

    func logout() async {
        if let r = TokenStorage.shared.read(.refresh) {
            _ = try? await api.request("/auth/logout", method: "POST", body: RefreshRequest(refresh_token: r)) as EmptyResponse
        }
        TokenStorage.shared.clear()
    }

    func refresh() async throws {
        guard let r = TokenStorage.shared.read(.refresh) else {
            throw APIError(message: "Sin refresh token")
        }
        let res: RefreshResponse = try await api.request(
            "/auth/refresh",
            method: "POST",
            body: RefreshRequest(refresh_token: r)
        )
        TokenStorage.shared.save(res.access_token, for: .access)
    }

    private func persist(_ t: AuthTokens) {
        TokenStorage.shared.save(t.accessToken, for: .access)
        TokenStorage.shared.save(t.refreshToken, for: .refresh)
    }
}
