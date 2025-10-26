import Foundation
import CryptoKit

enum PIIHashing {
    static func saltedHash(_ value: String, salt: Data) -> String {
        let data = Data(value.utf8) + salt
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
