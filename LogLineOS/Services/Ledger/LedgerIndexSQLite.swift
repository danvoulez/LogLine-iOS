import Foundation
import SQLite3
import OSLog

struct IndexedEvent: Identifiable {
    let id: String
    let timestamp: Date
    let day: String
    let entityName: String?
    let action: String
    let subject: String
    let value: Double?
    let currency: String?
    let payment: String?
}

final class LedgerIndexSQLite {
    static let shared = LedgerIndexSQLite()
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "ledger-index", qos: .utility)
    
    func ensureOpen() async throws {
        if db != nil { return }
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    try self.open()
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
    
    private func open() throws {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if !fm.fileExists(atPath: dir.path) { try fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        let url = dir.appendingPathComponent("ledger_index.sqlite")
        if sqlite3_open(url.path, &db) != SQLITE_OK { throw NSError(domain: "sqlite", code: 1) }
        try exec("""
        PRAGMA journal_mode=WAL;
        CREATE TABLE IF NOT EXISTS events(
          id TEXT PRIMARY KEY,
          ts REAL NOT NULL,
          day TEXT NOT NULL,
          entity_name TEXT,
          action TEXT NOT NULL,
          subject TEXT NOT NULL,
          value REAL,
          currency TEXT,
          payment TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_events_entity_day ON events(entity_name, day);
        """)
    }
    
    func index(canonical: Canonical, eventId: String, day: String, timestamp: Date) async throws {
        let entityName = canonical.entities.first?.name
        let e = canonical.events.first
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    try self.insertEvent(id: eventId, ts: timestamp, day: day, entity: entityName, action: e?.action.rawValue ?? "", subject: e?.subject ?? "", value: e?.value, currency: e?.currency, payment: e?.payment_method?.rawValue)
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
    
    func aggregateForEntity(named name: String, start: Date, end: Date) async throws -> (Int, Double) {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    let sql = "SELECT COUNT(*), COALESCE(SUM(value),0) FROM events WHERE entity_name = ? AND ts BETWEEN ? AND ? AND (action='sale' OR action='payment');"
                    var stmt: OpaquePointer?
                    defer { sqlite3_finalize(stmt) }
                    guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                        throw NSError(domain: "sqlite", code: 2)
                    }
                    sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_double(stmt, 2, start.timeIntervalSince1970)
                    sqlite3_bind_double(stmt, 3, end.timeIntervalSince1970)
                    guard sqlite3_step(stmt) == SQLITE_ROW else { throw NSError(domain: "sqlite", code: 3) }
                    let count = Int(sqlite3_column_int64(stmt, 0))
                    let total = sqlite3_column_double(stmt, 1)
                    cont.resume(returning: (count, total))
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
    
    func eventsFor(day: String) async throws -> [IndexedEvent] {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                var rows: [IndexedEvent] = []
                do {
                    let sql = "SELECT id, ts, day, entity_name, action, subject, value, currency, payment FROM events WHERE day = ? ORDER BY ts DESC;"
                    var stmt: OpaquePointer?
                    defer { sqlite3_finalize(stmt) }
                    guard sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK else {
                        throw NSError(domain: "sqlite", code: 2)
                    }
                    sqlite3_bind_text(stmt, 1, (day as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    while sqlite3_step(stmt) == SQLITE_ROW {
                        let id = String(cString: sqlite3_column_text(stmt, 0))
                        let ts = sqlite3_column_double(stmt, 1)
                        let day = String(cString: sqlite3_column_text(stmt, 2))
                        let entityName = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) }
                        let action = String(cString: sqlite3_column_text(stmt, 4))
                        let subject = String(cString: sqlite3_column_text(stmt, 5))
                        let value = sqlite3_column_type(stmt, 6) == SQLITE_NULL ? nil : sqlite3_column_double(stmt, 6)
                        let currency = sqlite3_column_text(stmt, 7).flatMap { String(cString: $0) }
                        let payment = sqlite3_column_text(stmt, 8).flatMap { String(cString: $0) }
                        rows.append(IndexedEvent(id: id, timestamp: Date(timeIntervalSince1970: ts), day: day, entityName: entityName, action: action, subject: subject, value: value, currency: currency, payment: payment))
                    }
                    cont.resume(returning: rows)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Internals
    
    private func insertEvent(id: String, ts: Date, day: String, entity: String?, action: String, subject: String, value: Double?, currency: String?, payment: String?) throws {
        let sql = "INSERT OR REPLACE INTO events (id, ts, day, entity_name, action, subject, value, currency, payment) VALUES (?,?,?,?,?,?,?,?,?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { throw NSError(domain: "sqlite", code: 2) }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 2, ts.timeIntervalSince1970)
        sqlite3_bind_text(stmt, 3, (day as NSString).utf8String, -1, SQLITE_TRANSIENT)
        if let entity { sqlite3_bind_text(stmt, 4, (entity as NSString).utf8String, -1, SQLITE_TRANSIENT) } else { sqlite3_bind_null(stmt, 4) }
        sqlite3_bind_text(stmt, 5, (action as NSString).utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 6, (subject as NSString).utf8String, -1, SQLITE_TRANSIENT)
        if let value { sqlite3_bind_double(stmt, 7, value) } else { sqlite3_bind_null(stmt, 7) }
        if let currency { sqlite3_bind_text(stmt, 8, (currency as NSString).utf8String, -1, SQLITE_TRANSIENT) } else { sqlite3_bind_null(stmt, 8) }
        if let payment { sqlite3_bind_text(stmt, 9, (payment as NSString).utf8String, -1, SQLITE_TRANSIENT) } else { sqlite3_bind_null(stmt, 9) }
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw NSError(domain: "sqlite", code: 3) }
    }
    
    private func exec(_ sql: String) throws {
        var err: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            let msg = err.flatMap { String(cString: $0) } ?? "unknown"
            throw NSError(domain: "sqlite", code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
}
