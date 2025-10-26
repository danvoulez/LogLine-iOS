import Foundation
import OSLog

final class AppEnvironment: ObservableObject {
    let detector: BusinessLanguageDetector
    let extractor: LLMExtractor
    let clarifier: ClarifierEngine
    let ledgerEngine: LedgerEngine
    let queryEngine: QueryEngine
    
    // DI bootstrap
    static func bootstrap() -> AppEnvironment {
        let detector = BusinessLanguageDetector()
        let keychain = HMACKeychain(service: "com.yourorg.loglineos.hmac")
        let ledger = LedgerEngine(keychain: keychain)
        let extractor: LLMExtractor = GeminiExtractor() // ou StubExtractor()
        let clarifier = ClarifierEngine()
        let queryEngine = QueryEngine(ledger: ledger)
        return AppEnvironment(detector: detector, extractor: extractor, clarifier: clarifier, ledgerEngine: ledger, queryEngine: queryEngine)
    }
    
    init(detector: BusinessLanguageDetector,
         extractor: LLMExtractor,
         clarifier: ClarifierEngine,
         ledgerEngine: LedgerEngine,
         queryEngine: QueryEngine) {
        self.detector = detector
        self.extractor = extractor
        self.clarifier = clarifier
        self.ledgerEngine = ledgerEngine
        self.queryEngine = queryEngine
    }
}
