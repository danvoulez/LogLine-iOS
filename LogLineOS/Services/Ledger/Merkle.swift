import Foundation
import CryptoKit

struct Merkle {
    static func hash(_ data: Data) -> Data { Data(SHA256.hash(data: data)) }
    
    // Constrói raíz a partir de folhas (já SHA-256 ou HMAC)
    static func root(leaves: [Data]) -> Data? {
        guard !leaves.isEmpty else { return nil }
        var level = leaves
        if level.count % 2 == 1 { level.append(level.last!) }
        while level.count > 1 {
            var next: [Data] = []
            for i in stride(from: 0, to: level.count, by: 2) {
                next.append(hash(level[i] + level[i+1]))
            }
            if next.count % 2 == 1 && next.count > 1 { next.append(next.last!) }
            level = next
        }
        return level.first
    }
    
    static func hex(_ d: Data) -> String { d.map { String(format: "%02x", $0) }.joined() }
}
