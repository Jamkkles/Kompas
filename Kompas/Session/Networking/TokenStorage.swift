import Foundation
import Security

enum TokenStorageKey: String {
    case access = "kompas.access"
    case refresh = "kompas.refresh"
}

final class TokenStorage {
    static let shared = TokenStorage()
    private init() {}

    func save(_ value: String, for key: TokenStorageKey) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: "Kompas.Session"
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attrs as CFDictionary, nil)
    }

    func read(_ key: TokenStorageKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: "Kompas.Session",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var ref: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &ref)
        guard status == errSecSuccess, let data = ref as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(_ key: TokenStorageKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: "Kompas.Session"
        ]
        SecItemDelete(query as CFDictionary)
    }

    func clear() {
        delete(.access); delete(.refresh)
    }
}
