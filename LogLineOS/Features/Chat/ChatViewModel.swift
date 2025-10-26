import Foundation
import SwiftUI
import OSLog

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, bot }
    let id = UUID()
    let role: Role
    let text: String
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var messages: [ChatMessage] = []
    
    private let env: AppEnvironment
    private var pending: ExtractionDraft?
    private var originalText: String = ""
    
    init(env: AppEnvironment) { self.env = env }
    
    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(.init(role: .user, text: text))
        input = ""
        Task { await handle(text: text) }
    }
    
    private func respond(_ s: String) {
        messages.append(.init(role: .bot, text: s))
    }
    
    private func handle(text: String) async {
        do {
            // If clarification pending
            if let pend = pending {
                let merged = try await env.extractor.merge(clarification: text, originalText: originalText, existing: pend)
                if let q = env.clarifier.nextQuestion(for: merged) {
                    pending = merged
                    respond(q.question)
                    return
                } else {
                    // commit
                    let receipt = try await env.ledgerEngine.append(canonical: merged.canonical, originalText: originalText + " | " + text, actor: "chat/user")
                    pending = nil
                    respond("✅ Registrado!\nEvent: \(receipt.eventId)\nDia: \(receipt.day)\nMerkle: \(receipt.merkleRootHex ?? "-")")
                    return
                }
            }
            
            // Detect business language or treat as query
            if env.detector.isBusinessLanguage(text) {
                originalText = text
                let draft = try await env.extractor.extract(from: text)
                if let q = env.clarifier.nextQuestion(for: draft) {
                    pending = draft
                    respond(q.question)
                } else {
                    let receipt = try await env.ledgerEngine.append(canonical: draft.canonical, originalText: text, actor: "chat/user")
                    respond("✅ Registrado!\nEvent: \(receipt.eventId)\nDia: \(receipt.day)\nMerkle: \(receipt.merkleRootHex ?? "-")")
                }
            } else {
                // Simple query: "quantas vezes a Amanda comprou este mês?"
                if let name = extractName(from: text) {
                    let (count, total) = try await env.queryEngine.purchasesFor(name, monthOf: Date())
                    respond("\(name) teve \(count) transações este mês, totalizando \(String(format: "R$ %.2f", total)).")
                } else {
                    respond("Posso registrar algo ou responder perguntas como: "quantas vezes a Amanda comprou este mês?".")
                }
            }
        } catch {
            Logger.app.error("Chat error: \(error.localizedDescription)")
            respond("Desculpe, houve um erro: \(error.localizedDescription)")
        }
    }
    
    private func extractName(from text: String) -> String? {
        // simplista: captura primeira palavra com maiúscula dupla
        let words = text.split(separator: " ").map(String.init)
        for i in 0..<max(0, words.count-1) {
            if words[i].first?.isUppercase == true, words[i+1].first?.isUppercase == true {
                return words[i] + " " + words[i+1]
            }
        }
        return nil
    }
}
