import XCTest
@testable import LogLineOS

final class DataExporterTests: XCTestCase {
    
    let exporter = DataExporter()
    
    func testExportToCSV() throws {
        let events = createSampleEvents()
        let csv = try exporter.exportToCSV(events)
        
        XCTAssertTrue(csv.contains("ID,Timestamp,Day,Entity,Action,Subject,Value,Currency,Payment"))
        XCTAssertTrue(csv.contains("Amanda Barros"))
        XCTAssertTrue(csv.contains("sale"))
    }
    
    func testExportToJSON() throws {
        let events = createSampleEvents()
        let json = try exporter.exportToJSON(events)
        
        XCTAssertTrue(json.contains("id"))
        XCTAssertTrue(json.contains("timestamp"))
        XCTAssertTrue(json.contains("Amanda Barros"))
    }
    
    func testExportEmptyData() {
        let events: [IndexedEvent] = []
        
        XCTAssertThrowsError(try exporter.exportToCSV(events)) { error in
            XCTAssertTrue(error is ExportError)
        }
        
        XCTAssertThrowsError(try exporter.exportToJSON(events)) { error in
            XCTAssertTrue(error is ExportError)
        }
    }
    
    func testGenerateSummary() {
        let events = createSampleEvents()
        let summary = exporter.generateSummary(events)
        
        XCTAssertEqual(summary["total_transactions"] as? Int, 2)
        XCTAssertEqual(summary["unique_entities"] as? Int, 1)
        
        if let actionBreakdown = summary["action_breakdown"] as? [String: Int] {
            XCTAssertEqual(actionBreakdown["sale"], 1)
            XCTAssertEqual(actionBreakdown["payment"], 1)
        } else {
            XCTFail("action_breakdown not found or wrong type")
        }
    }
    
    func testCSVEscaping() throws {
        let event = IndexedEvent(
            id: "evt:123",
            timestamp: Date(),
            day: "2025-01-01",
            entityName: "Test, \"Entity\"",
            action: "sale",
            subject: "Product with, comma",
            value: 100,
            currency: "BRL",
            payment: "pix"
        )
        
        let csv = try exporter.exportToCSV([event])
        
        // CSV should properly escape values with commas and quotes
        XCTAssertTrue(csv.contains("\"Test, \"\"Entity\"\"\""))
        XCTAssertTrue(csv.contains("\"Product with, comma\""))
    }
    
    // MARK: - Helpers
    
    private func createSampleEvents() -> [IndexedEvent] {
        return [
            IndexedEvent(
                id: "evt:1",
                timestamp: Date(),
                day: Date().dayKey,
                entityName: "Amanda Barros",
                action: "sale",
                subject: "camisetas",
                value: 120.0,
                currency: "BRL",
                payment: "pix"
            ),
            IndexedEvent(
                id: "evt:2",
                timestamp: Date(),
                day: Date().dayKey,
                entityName: "Amanda Barros",
                action: "payment",
                subject: "payment received",
                value: 120.0,
                currency: "BRL",
                payment: "pix"
            )
        ]
    }
}
