import Foundation
import OSLog

final class GeminiExtractor: LLMExtractor {
    private let session = URLSession(configuration: .ephemeral)
    private let apiKey: String?
    private let model = "models/gemini-1.5-pro-latest"
    private let base = "https://generativelanguage.googleapis.com/v1beta/"
    
    init() {
        self.apiKey = Secrets.read(key: "GEMINI_API_KEY")
    }
    
    func extract(from text: String) async throws -> ExtractionDraft {
        guard let apiKey else { Logger.extract.warning("No GEMINI_API_KEY; falling back to stub"); return try await StubExtractor().extract(from: text) }
        let url = URL(string: "\(base)\(model):generateContent?key=\(apiKey)")!
        let prompt = Self.extractionPrompt(text: text)
        let body = ["contents": [["parts": [["text": prompt]]]], "generationConfig": ["response_mime_type": "application/json"]]] as [String : Any]
        let (data, _) = try await session.data(for: URLRequest.jsonPOST(url: url, json: body))
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let partText = response.candidates.first?.content.parts.first?.text ?? "{}"
        let canonical = try JSONDecoder().decode(Canonical.self, from: Data(partText.utf8))
        return ExtractionDraft(canonical: canonical, incompleteFields: canonical.incompleteFields())
    }
    
    func merge(clarification: String, originalText: String, existing: ExtractionDraft) async throws -> ExtractionDraft {
        guard let apiKey else { return try await StubExtractor().merge(clarification: clarification, originalText: originalText, existing: existing) }
        let url = URL(string: "\(base)models/gemini-1.5-flash-latest:generateContent?key=\(apiKey)")!
        let prompt = Self.mergePrompt(originalText: originalText, existing: existing.canonical, clarification: clarification, missing: existing.incompleteFields)
        let body = ["contents": [["parts": [["text": prompt]]]], "generationConfig": ["response_mime_type": "application/json"]]] as [String : Any]
        let (data, _) = try await session.data(for: URLRequest.jsonPOST(url: url, json: body))
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let partText = response.candidates.first?.content.parts.first?.text ?? "{}"
        let canonical = try JSONDecoder().decode(Canonical.self, from: Data(partText.utf8))
        return ExtractionDraft(canonical: canonical, incompleteFields: canonical.incompleteFields())
    }
    
    private static func extractionPrompt(text: String) -> String {
        """
        You are a small business ledger assistant. Extract structured data from this natural language business description. Return ONLY valid JSON in the canonical schema below.

        TEXT: "\(text)"
        SCHEMA: \(Canonical.jsonSchemaString())
        """
    }
    private static func mergePrompt(originalText: String, existing: Canonical, clarification: String, missing: [String]) -> String {
        """
        Merge this clarification into the existing extracted data and return ONLY the complete JSON in the canonical schema.

        ORIGINAL: "\(originalText)"
        EXISTING: \(existing.toJSONString())
        CLARIFICATION: "\(clarification)"
        MISSING_FIELDS: \(missing)
        SCHEMA: \(Canonical.jsonSchemaString())
        """
    }
}

// MARK: - Helpers

private struct GeminiResponse: Codable {
    struct Candidate: Codable { let content: Content }
    struct Content: Codable { let parts: [Part] }
    struct Part: Codable { let text: String }
    let candidates: [Candidate]
}

enum Secrets {
    static func read(key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any] else { return nil }
        return dict[key] as? String
    }
}

extension URLRequest {
    static func jsonPOST(url: URL, json: [String: Any]) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: json, options: [])
        return req
    }
}
