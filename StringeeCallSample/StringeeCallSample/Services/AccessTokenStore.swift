import Foundation
import Security

protocol AccessTokenStoreProtocol: AnyObject {
    func loadAccessToken() -> String?
    func saveAccessToken(_ token: String)
    func deleteAccessToken()
}

final class AccessTokenStore: AccessTokenStoreProtocol {
    private let service = "com.stringee.StringeeCallSample"
    private let account = "access-token"

    func loadAccessToken() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveAccessToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        var query = baseQuery()
        let attributes = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    func deleteAccessToken() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

final class InMemoryAccessTokenStore: AccessTokenStoreProtocol {
    private var token: String?

    func loadAccessToken() -> String? {
        token
    }

    func saveAccessToken(_ token: String) {
        self.token = token
    }

    func deleteAccessToken() {
        token = nil
    }
}
