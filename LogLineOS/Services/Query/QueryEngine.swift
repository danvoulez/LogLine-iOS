import Foundation

final class QueryEngine {
    private let ledger: LedgerEngine
    init(ledger: LedgerEngine) { self.ledger = ledger }
    
    func purchasesFor(_ name: String, monthOf date: Date) async throws -> (count: Int, total: Double) {
        let cal = Calendar(identifier: .iso8601)
        let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        return try await ledger.queryTransactions(for: name, from: start, to: end)
    }
    
    func purchasesFor(_ name: String, from start: Date, to end: Date) async throws -> (count: Int, total: Double) {
        return try await ledger.queryTransactions(for: name, from: start, to: end)
    }
    
    func allEntities() async throws -> [String] {
        return try await ledger.allEntities()
    }
    
    func searchEvents(query: String) async throws -> [IndexedEvent] {
        return try await ledger.searchEvents(query: query)
    }
    
    func eventsInDateRange(from start: Date, to end: Date) async throws -> [IndexedEvent] {
        return try await ledger.eventsInDateRange(from: start, to: end)
    }
    
    func topCustomers(limit: Int = 10, from start: Date, to end: Date) async throws -> [(name: String, count: Int, total: Double)] {
        let entities = try await allEntities()
        var results: [(String, Int, Double)] = []
        
        for entity in entities {
            let (count, total) = try await purchasesFor(entity, from: start, to: end)
            if count > 0 {
                results.append((entity, count, total))
            }
        }
        
        // Sort by total value descending
        results.sort { $0.2 > $1.2 }
        return Array(results.prefix(limit))
    }
}
