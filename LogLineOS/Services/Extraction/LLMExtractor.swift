import Foundation
import OSLog

struct ExtractionDraft: Codable {
    var canonical: Canonical
    var incompleteFields: [String]
}

protocol LLMExtractor {
    func extract(from text: String) async throws -> ExtractionDraft
    func merge(clarification: String, originalText: String, existing: ExtractionDraft) async throws -> ExtractionDraft
}

// Stub para dev offline
struct StubExtractor: LLMExtractor {
    func extract(from text: String) async throws -> ExtractionDraft {
        let sample = Canonical.sampleAmanda()
        return ExtractionDraft(canonical: sample, incompleteFields: sample.incompleteFields())
    }
    func merge(clarification: String, originalText: String, existing: ExtractionDraft) async throws -> ExtractionDraft {
        var c = existing.canonical
        if clarification.localizedCaseInsensitiveContains("120") { c.events[0].value = 120; c.events[0].currency = "BRL" }
        if clarification.localizedCaseInsensitiveContains("pix") { c.events[0].payment_method = .pix }
        return ExtractionDraft(canonical: c, incompleteFields: c.incompleteFields())
    }
}
