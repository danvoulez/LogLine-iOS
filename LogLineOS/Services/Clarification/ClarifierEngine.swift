import Foundation

struct ClarifierPrompt {
    let question: String
    let missing: [String]
}

final class ClarifierEngine {
    func nextQuestion(for draft: ExtractionDraft) -> ClarifierPrompt? {
        let missing = draft.incompleteFields
        guard let first = missing.first else { return nil }
        let q: String
        switch true {
        case first.localizedCaseInsensitiveContains("person") || first.contains("full_name"):
            q = "Qual o nome completo do cliente?"
        case first.localizedCaseInsensitiveContains("transaction_value") || first.localizedCaseInsensitiveContains("value"):
            q = "Qual foi o valor total?"
        case first.localizedCaseInsensitiveContains("payment"):
            q = "Foi pago em dinheiro, cartão, Pix ou crédito da loja?"
        default:
            q = "Pode me dar mais detalhes (\(first))?"
        }
        return ClarifierPrompt(question: q, missing: missing)
    }
}
