import XCTest
@testable import LogLineOS

final class EnhancedFeaturesTests: XCTestCase {
    
    func testIndexedEventProperties() {
        let event = IndexedEvent(
            id: "evt:test",
            timestamp: Date(),
            day: Date().dayKey,
            entityName: "Test Entity",
            action: "sale",
            subject: "test product",
            value: 99.99,
            currency: "BRL",
            payment: "credit"
        )
        
        XCTAssertEqual(event.entityName, "Test Entity")
        XCTAssertEqual(event.action, "sale")
        XCTAssertEqual(event.value, 99.99)
        XCTAssertEqual(event.currency, "BRL")
    }
    
    func testCurrencyFormatting() {
        let value: Double = 1234.56
        let formatted = value.currencyFormatted
        
        // Should contain currency symbol and formatted value
        XCTAssertTrue(formatted.contains("1234") || formatted.contains("1.234"))
    }
    
    func testEntityStatsCalculation() {
        let events = [
            createEvent(value: 100),
            createEvent(value: 200),
            createEvent(value: 300)
        ]
        
        let totalValue = events.reduce(0.0) { $0 + ($1.value ?? 0) }
        let average = totalValue / Double(events.count)
        
        XCTAssertEqual(totalValue, 600.0)
        XCTAssertEqual(average, 200.0)
    }
    
    func testSearchFiltering() {
        let events = [
            IndexedEvent(id: "1", timestamp: Date(), day: "2025-01-01", entityName: "Amanda Barros", action: "sale", subject: "camisetas", value: 100, currency: "BRL", payment: "pix"),
            IndexedEvent(id: "2", timestamp: Date(), day: "2025-01-01", entityName: "João Silva", action: "purchase", subject: "livros", value: 50, currency: "BRL", payment: "credit"),
            IndexedEvent(id: "3", timestamp: Date(), day: "2025-01-01", entityName: "Amanda Barros", action: "return", subject: "calça", value: 80, currency: "BRL", payment: nil)
        ]
        
        // Filter by entity name
        let amandaEvents = events.filter { $0.entityName?.contains("Amanda") == true }
        XCTAssertEqual(amandaEvents.count, 2)
        
        // Filter by action
        let saleEvents = events.filter { $0.action == "sale" }
        XCTAssertEqual(saleEvents.count, 1)
    }
    
    func testDateRangeFiltering() {
        let cal = Calendar.current
        let now = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now)!
        
        let events = [
            createEvent(timestamp: yesterday),
            createEvent(timestamp: now),
            createEvent(timestamp: tomorrow)
        ]
        
        // Filter events in date range
        let todayEvents = events.filter { event in
            let startOfDay = cal.startOfDay(for: now)
            let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
            return event.timestamp >= startOfDay && event.timestamp < endOfDay
        }
        
        XCTAssertEqual(todayEvents.count, 1)
    }
    
    func testTimePeriodEnum() {
        let periods = QueryViewModel.TimePeriod.allCases
        XCTAssertEqual(periods.count, 5)
        XCTAssertTrue(periods.contains(.thisWeek))
        XCTAssertTrue(periods.contains(.thisMonth))
        XCTAssertTrue(periods.contains(.custom))
    }
    
    // MARK: - Helpers
    
    private func createEvent(value: Double = 100, timestamp: Date = Date()) -> IndexedEvent {
        return IndexedEvent(
            id: UUID().uuidString,
            timestamp: timestamp,
            day: timestamp.dayKey,
            entityName: "Test Entity",
            action: "sale",
            subject: "test",
            value: value,
            currency: "BRL",
            payment: "pix"
        )
    }
}
