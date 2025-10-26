import XCTest
@testable import LogLineOS

final class ExtractionTests: XCTestCase {
    func testBusinessLanguageDetection() async throws {
        let detector = BusinessLanguageDetector()
        
        // Portuguese business language
        XCTAssertTrue(detector.isBusinessLanguage("Cliente comprou 3 produtos"))
        XCTAssertTrue(detector.isBusinessLanguage("Pagou com Pix"))
        XCTAssertTrue(detector.isBusinessLanguage("Vendeu ontem"))
        
        // Non-business language
        XCTAssertFalse(detector.isBusinessLanguage("Olá, como vai?"))
        XCTAssertFalse(detector.isBusinessLanguage(""))
    }
    
    func testStubExtractor() async throws {
        let extractor = StubExtractor()
        let draft = try await extractor.extract(from: "Amanda comprou algo")
        
        XCTAssertFalse(draft.canonical.entities.isEmpty)
        XCTAssertEqual(draft.canonical.entities.first?.name, "Amanda Barros")
        XCTAssertTrue(draft.incompleteFields.contains("transaction_value"))
    }
}
