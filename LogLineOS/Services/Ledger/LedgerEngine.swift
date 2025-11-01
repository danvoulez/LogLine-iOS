import Foundation
import OSLog

struct LedgerReceipt: Codable {
    let eventId: String
    let day: String
    let eventHashHex: String
    let chainHashHex: String
    let merkleRootHex: String?
}

actor LedgerEngine {
    private let keychain: HMACKeychain
    private let fm = FileManager.default
    private let index = LedgerIndexSQLite.shared
    private var currentDay: String = Date().dayKey
    private var prevChainHash: Data = Data()
    private var dayHashes: [Data] = []
    
    init(keychain: HMACKeychain) {
        self.keychain = keychain
    }
    
    func warmUp() {
        Task { await loadDayState(for: Date().dayKey) }
    }
    
    // MARK: Public API
    
    func append(canonical: Canonical, originalText: String, actor: String) async throws -> LedgerReceipt {
        let day = Date().dayKey
        if day != currentDay { try await rolloverDay(to: day) }
        
        // 1) canonical JSON deterministic
        let payload = try CanonicalJSON.encode(canonical)
        let rowId = "evt:" + UUID().uuidString.lowercased()
        let traceId = "tr:biz:\(Int(Date().timeIntervalSince1970)):\(UUID().uuidString.prefix(8))"
        let spanId = "sp:event:0"
        
        // 2) HMAC row hash
        let rowHash = try keychain.hmac(payload)
        
        // 3) chain hash = HMAC(prev || rowHash)
        let chainHash = try keychain.hmac(prevChainHash + rowHash)
        prevChainHash = chainHash
        dayHashes.append(rowHash)
        
        // 4) Write NDJSON line
        let line = try makeNDJSONLine(
            id: rowId, traceId: traceId, spanId: spanId, actor: actor,
            canonical: canonical, originalText: originalText,
            rowHash: rowHash, chainHash: chainHash
        )
        try appendLine(line, day: day)
        
        // 5) Update index (SQLite)
        try await index.ensureOpen()
        try await index.index(canonical: canonical, eventId: rowId, day: day, timestamp: Date())
        
        // 6) Compute Merkle root (incremental)
        let root = Merkle.root(leaves: dayHashes)
        let receipt = LedgerReceipt(
            eventId: rowId,
            day: day,
            eventHashHex: Merkle.hex(rowHash),
            chainHashHex: Merkle.hex(chainHash),
            merkleRootHex: root.map { Merkle.hex($0) }
        )
        try writeManifest(day: day, lastChain: chainHash, root: root)
        return receipt
    }
    
    func queryTransactions(for name: String, from start: Date, to end: Date) async throws -> (count: Int, total: Double) {
        try await index.ensureOpen()
        return try await index.aggregateForEntity(named: name, start: start, end: end)
    }
    
    func eventsFor(day: String) async throws -> [IndexedEvent] {
        try await index.ensureOpen()
        return try await index.eventsFor(day: day)
    }
    
    func allEventsForEntity(named name: String) async throws -> [IndexedEvent] {
        try await index.ensureOpen()
        return try await index.allEventsForEntity(named: name)
    }
    
    func allEntities() async throws -> [String] {
        try await index.ensureOpen()
        return try await index.allEntityNames()
    }
    
    func searchEvents(query: String) async throws -> [IndexedEvent] {
        try await index.ensureOpen()
        return try await index.searchEvents(query: query)
    }
    
    func eventsInDateRange(from start: Date, to end: Date) async throws -> [IndexedEvent] {
        try await index.ensureOpen()
        return try await index.eventsInDateRange(start: start, end: end)
    }
    
    // MARK: Internals
    
    private func makeNDJSONLine(id: String, traceId: String, spanId: String, actor: String, canonical: Canonical, originalText: String, rowHash: Data, chainHash: Data) throws -> String {
        let record: [String: Any] = [
            "id": id,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "traceId": traceId,
            "spanId": spanId,
            "actor": actor,
            "action": canonical.events.first?.action.rawValue ?? "business.event",
            "subject": canonical.events.first?.subject ?? "",
            "canonical": try JSONSerialization.jsonObject(with: CanonicalJSON.encode(canonical)),
            "attrs": [
                "originalText": originalText,
                "temporal": canonical.temporal?.when ?? canonical.temporal?.inferred_date ?? "",
                "location": canonical.location?.mentioned ?? ""
            ],
            "row_hash": Merkle.hex(rowHash),
            "chain_hash": Merkle.hex(chainHash)
        ]
        let data = try JSONSerialization.data(withJSONObject: record, options: [])
        return String(data: data, encoding: .utf8)! + "\n"
    }
    
    private func appendLine(_ line: String, day: String) throws {
        let dir = try ensureLedgerDir()
        let path = dir.appendingPathComponent("\(day).ndjson")
        if fm.fileExists(atPath: path.path) {
            let handle = try FileHandle(forWritingTo: path)
            try handle.seekToEnd()
            if let d = line.data(using: .utf8) { try handle.write(contentsOf: d) }
            try handle.close()
        } else {
            try line.write(to: path, atomically: true, encoding: .utf8)
        }
    }
    
    private func loadDayState(for day: String) {
        self.currentDay = day
        self.prevChainHash = Data()
        self.dayHashes = []
        // tenta ler manifest existente
        if let manifest = try? readManifest(day: day) {
            self.prevChainHash = Data(hex: manifest.lastChain ?? "") ?? Data()
            self.dayHashes = (manifest.rowHashesHex ?? []).compactMap { Data(hex: $0) }
        }
    }
    
    private func rolloverDay(to day: String) throws {
        // finalize dia anterior (já persistimos manifest incremental)
        loadDayState(for: day)
    }
    
    private func ensureLedgerDir() throws -> URL {
        let lib = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = lib.appendingPathComponent("ledger", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) { try fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }
    
    // Manifest para auditoria diária
    private struct Manifest: Codable { let day: String; let lastChain: String?; let merkleRoot: String?; let rowHashesHex: [String]? }
    
    private func writeManifest(day: String, lastChain: Data?, root: Data?) throws {
        let m = Manifest(day: day, lastChain: lastChain.map(Merkle.hex), merkleRoot: root.map(Merkle.hex), rowHashesHex: dayHashes.map(Merkle.hex))
        let data = try JSONEncoder().encode(m)
        let dir = try ensureLedgerDir()
        try data.write(to: dir.appendingPathComponent("\(day).manifest.json"))
    }
    private func readManifest(day: String) throws -> Manifest {
        let dir = try ensureLedgerDir()
        let url = dir.appendingPathComponent("\(day).manifest.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Manifest.self, from: data)
    }
}

private extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var index = hex.startIndex
        for _ in 0..<len {
            let next = hex.index(index, offsetBy: 2)
            if next > hex.endIndex { return nil }
            let bytes = hex[index..<next]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else { return nil }
            index = next
        }
        self = data
    }
}
