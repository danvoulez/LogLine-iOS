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
}
