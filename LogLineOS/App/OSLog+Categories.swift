import OSLog

extension Logger {
    static let app = Logger(subsystem: "com.yourorg.loglineos", category: "app")
    static let ingest = Logger(subsystem: "com.yourorg.loglineos", category: "ingest")
    static let ledger = Logger(subsystem: "com.yourorg.loglineos", category: "ledger")
    static let extract = Logger(subsystem: "com.yourorg.loglineos", category: "extract")
    static let query = Logger(subsystem: "com.yourorg.loglineos", category: "query")
    static let security = Logger(subsystem: "com.yourorg.loglineos", category: "security")
}
