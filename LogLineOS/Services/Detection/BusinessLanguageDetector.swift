import Foundation

struct BusinessLanguageDetector {
    // PT/EN/ES + contexto
    private let patterns: [NSRegularExpression] = [
        // Portuguese verbs/nouns
        try! NSRegularExpression(pattern: "(comprou|vendeu|devolveu|trocou|pagou|recebeu|entregou|reservou)", options: .caseInsensitive),
        try! NSRegularExpression(pattern: "(cliente|fornecedor|produto|servi[cç]o|pedido|venda|compra)", options: .caseInsensitive),
        try! NSRegularExpression(pattern: "(reais|r\\$|cr[eé]dito|dinheiro|pix|cart[aã]o|d[eé]bito|boleto)", options: .caseInsensitive),
        // English
        try! NSRegularExpression(pattern: "(bought|sold|returned|exchanged|paid|received|delivered|reserved)", options: .caseInsensitive),
        try! NSRegularExpression(pattern: "(customer|supplier|product|service|order|sale|purchase|invoice|cash|card)", options: .caseInsensitive),
        // Spanish
        try! NSRegularExpression(pattern: "(compr[oó]|vend[ií]o|devolvi[oó]|cambi[oó]|pag[oó]|recibi[oó]|entreg[oó])", options: .caseInsensitive),
        // Colloquial refs + temporal
        try! NSRegularExpression(pattern: "(a\\s+loira|o\\s+moreno|aquela?\\s+que|o\\s+que\\s+mora)", options: .caseInsensitive),
        try! NSRegularExpression(pattern: "(ontem|hoje|semana passada|m[eê]s passado|amanh[aã])", options: .caseInsensitive)
    ]
    
    func isBusinessLanguage(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        for re in patterns {
            if re.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil {
                return true
            }
        }
        return false
    }
}
