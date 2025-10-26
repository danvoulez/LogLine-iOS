import XCTest
@testable import LogLineOS

final class LedgerTests: XCTestCase {
    func testCanonicalIncompleteFields() {
        var c = Canonical.sampleAmanda()
        XCTAssertTrue(c.incompleteFields().contains("transaction_value"))
        c.events[0].value = 120
        c.events[0].payment_method = .pix
        XCTAssertFalse(c.incompleteFields().contains("transaction_value"))
    }
}
