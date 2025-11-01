import Foundation

enum ExportFormat {
    case csv
    case json
}

enum ExportError: Error {
    case noData
    case exportFailed(String)
}

final class DataExporter {
    
    /// Export events to CSV format
    func exportToCSV(_ events: [IndexedEvent]) throws -> String {
        guard !events.isEmpty else { throw ExportError.noData }
        
        var csv = "ID,Timestamp,Day,Entity,Action,Subject,Value,Currency,Payment\n"
        
        for event in events {
            let fields = [
                escapeCSV(event.id),
                escapeCSV(event.timestamp.ISO8601Format()),
                escapeCSV(event.day),
                escapeCSV(event.entityName ?? ""),
                escapeCSV(event.action),
                escapeCSV(event.subject),
                event.value.map { String($0) } ?? "",
                escapeCSV(event.currency ?? ""),
                escapeCSV(event.payment ?? "")
            ]
            csv += fields.joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    /// Export events to JSON format
    func exportToJSON(_ events: [IndexedEvent]) throws -> String {
        guard !events.isEmpty else { throw ExportError.noData }
        
        let exportData = events.map { event in
            [
                "id": event.id,
                "timestamp": event.timestamp.ISO8601Format(),
                "day": event.day,
                "entity_name": event.entityName ?? "",
                "action": event.action,
                "subject": event.subject,
                "value": event.value.map { String($0) } ?? "",
                "currency": event.currency ?? "",
                "payment": event.payment ?? ""
            ]
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.exportFailed("Failed to serialize JSON")
        }
        
        return jsonString
    }
    
    /// Save data to file and return URL
    func saveToFile(content: String, filename: String, format: ExportFormat) throws -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileExtension = format == .csv ? "csv" : "json"
        let fileURL = tempDir.appendingPathComponent("\(filename).\(fileExtension)")
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    /// Generate summary statistics for export
    func generateSummary(_ events: [IndexedEvent]) -> [String: Any] {
        let totalTransactions = events.count
        let totalValue = events.compactMap { $0.value }.reduce(0, +)
        let averageValue = totalTransactions > 0 ? totalValue / Double(totalTransactions) : 0
        
        let entities = Set(events.compactMap { $0.entityName })
        let actions = events.map { $0.action }
        let actionCounts = Dictionary(grouping: actions, by: { $0 })
            .mapValues { $0.count }
        
        let firstDate = events.map { $0.timestamp }.min()
        let lastDate = events.map { $0.timestamp }.max()
        
        return [
            "total_transactions": totalTransactions,
            "total_value": totalValue,
            "average_value": averageValue,
            "unique_entities": entities.count,
            "action_breakdown": actionCounts,
            "date_range": [
                "start": firstDate?.ISO8601Format() ?? "",
                "end": lastDate?.ISO8601Format() ?? ""
            ]
        ]
    }
    
    // MARK: - Private Helpers
    
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
