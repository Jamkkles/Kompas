import Foundation

struct APIError: Error, Decodable {
    let message: String
}

struct EmptyResponse: Decodable {}

struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ value: Encodable) { self.encodeFunc = value.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

final class APIClient {
    static let shared = APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!) // ← tu backend local

    private let baseURL: URL
    private let session: URLSession

    // Inyectados por AuthRepository
    var tokenProvider: () -> String? = { TokenStorage.shared.read(.access) }
    var refreshAction: () async throws -> Void = { throw APIError(message: "Refresh no configurado") }

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil,
        authorized: Bool = false
    ) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authorized, let token = tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        // Debug: request
        #if DEBUG
        debugPrint("➡️ \(method) \(req.url!.absoluteString)")
        if let headers = req.allHTTPHeaderFields { debugPrint("Headers:", headers) }
        if let b = req.httpBody, let s = String(data: b, encoding: .utf8) { debugPrint("Body:", s) }
        #endif

        let (data, response) = try await session.data(for: req)

        // Debug: response
        #if DEBUG
        if let http = response as? HTTPURLResponse {
            debugPrint("⬅️ \(http.statusCode) for \(method) \(path)")
        }
        if let txt = String(data: data, encoding: .utf8) { debugPrint("RespBody:", txt) }
        #endif

        // 401 → refresh + retry (una vez)
        if let http = response as? HTTPURLResponse, http.statusCode == 401, authorized {
            try await refreshAction()
            return try await self.request(path, method: method, body: body, authorized: authorized)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) { throw apiErr }
            throw APIError(message: "Error HTTP desconocido")
        }

        if T.self == EmptyResponse.self { return EmptyResponse() as! T }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
