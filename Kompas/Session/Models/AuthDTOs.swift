import Foundation

struct AuthLoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthRegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let accessExpiresIn: Int
    let refreshExpiresIn: Int
}

struct AuthUserEnvelope: Codable {
    let user: User
    let access_token: String
    let refresh_token: String
    let access_expires_in: Int
    let refresh_expires_in: Int

    var tokens: AuthTokens {
        AuthTokens(
            accessToken: access_token,
            refreshToken: refresh_token,
            accessExpiresIn: access_expires_in,
            refreshExpiresIn: refresh_expires_in
        )
    }
}

struct RefreshRequest: Codable {
    let refresh_token: String
}

struct RefreshResponse: Codable {
    let access_token: String
    let access_expires_in: Int
}
