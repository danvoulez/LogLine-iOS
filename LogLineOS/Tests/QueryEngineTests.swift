import XCTest
@testable import LogLineOS

final class QueryEngineTests: XCTestCase {
    
    func testPurchasesForMonth() async throws {
        // This test would need a mock LedgerEngine
        // For now, we'll test the date range calculation logic
        let cal = Calendar(identifier: .iso8601)
        let date = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        
        XCTAssertTrue(start < end)
        XCTAssertEqual(cal.component(.month, from: start), cal.component(.month, from: date))
    }
    
    func testDateRangeCalculations() {
        let cal = Calendar.current
        let now = Date()
        
        // Test week range
        let weekStart = cal.date(byAdding: .day, value: -7, to: now)!
        XCTAssertTrue(weekStart < now)
        
        // Test month range
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        XCTAssertTrue(monthStart <= now)
    }
}
