import Foundation
import CryptoKit
import OSLog

final class HMACKeychain {
    private let service: String
    private let account = "ledger-hmac-key"
    init(service: String) { self.service = service }
    
    func ensureKey() throws -> SymmetricKey {
        if let k = try readKey() { return k }
        let key = SymmetricKey(size: .bits256)
        try saveKey(key)
        return key
    }
    
    private func readKey() throws -> SymmetricKey? {
        var query: [String: Any] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = account
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return SymmetricKey(data: data)
    }
    
    private func saveKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
    
    func hmac(_ data: Data) throws -> Data {
        let key = try ensureKey()
        let mac = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(mac)
    }
}
