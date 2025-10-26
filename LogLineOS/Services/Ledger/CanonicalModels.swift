import Foundation

// MARK: - Canonical Schema

struct Canonical: Codable {
    var entities: [Entity] = []
    var events: [Event] = []
    var temporal: Temporal?
    var location: Location?
    var relationships: [Relationship] = []
    var sentiment: String?
    var raw_facts: [String]?
    
    func incompleteFields() -> [String] {
        var miss: [String] = []
        if entities.isEmpty { miss.append("person_identity") }
        for e in events {
            if e.action == .sale && e.value == nil { miss.append("transaction_value") }
            if (e.action == .sale || e.action == .payment), e.payment_method == nil { miss.append("payment_method") }
        }
        return Array(Set(miss))
    }
    
    static func jsonSchemaString() -> String {
        // short, for LLM prompt
        """
        {
          "entities":[{"id":"string?","name":"string","type":"Person|Organization|Product|Location","role":"customer|supplier|employee|product|service","aliases":["string"],"notes":"string?"}],
          "events":[{"action":"sale|purchase|return|exchange|payment|delivery|reservation|inquiry","subject":"string","quantity":"number?","value":"number?","currency":"BRL|USD|EUR?","payment_method":"cash|credit|debit|pix|store_credit?","outcome":"completed|pending|cancelled|satisfied|unsatisfied|partial_failure?","reason":"string?"}],
          "temporal":{"when":"string?","inferred_date":"ISO?"},
          "location":{"mentioned":"string?","inferred":"string?"},
          "relationships":[{"entity1":"string","relation":"lives_in|works_at|bought_from|returned_to|supplies","entity2":"string"}],
          "sentiment":"positive|neutral|negative?",
          "raw_facts":["string"]
        }
        """
    }
    
    func toJSONString() -> String {
        (try? String(data: JSONEncoder().encode(self), encoding: .utf8)) ?? "{}"
    }
    
    // Demo sample
    static func sampleAmanda() -> Canonical {
        Canonical(
            entities: [Entity(id: nil, name: "Amanda Barros", type: .person, role: "customer", aliases: ["a loira de São Paulo"], notes: nil)],
            events: [
                Event(action: .sale, subject: "camisetas", quantity: 2, value: nil, currency: "BRL", payment_method: nil, outcome: .completed, reason: nil, meta: [:]),
                Event(action: .return, subject: "calça jeans", quantity: 1, value: nil, currency: "BRL", payment_method: .store_credit, outcome: .satisfied, reason: "tight", meta: [:])
            ],
            temporal: Temporal(when: "today", inferred_date: ISO8601DateFormatter().string(from: Date())),
            location: Location(mentioned: "São Paulo", inferred: "Store #1"),
            relationships: [Relationship(entity1: "Amanda Barros", relation: "bought_from", entity2: "VoulezVous")],
            sentiment: "positive",
            raw_facts: ["returned tight jeans; store credit only", "paid Pix; satisfied"]
        )
    }
}

struct Entity: Codable {
    enum EType: String, Codable { case person = "Person", organization = "Organization", product = "Product", location = "Location" }
    var id: String?
    var name: String
    var type: EType
    var role: String?
    var aliases: [String]?
    var notes: String?
}

struct Event: Codable {
    enum Action: String, Codable { case sale, purchase, `return`, exchange, payment, delivery, reservation, inquiry }
    enum Payment: String, Codable { case cash, credit, debit, pix, store_credit, voucher, transfer }
    enum Outcome: String, Codable { case completed, pending, cancelled, satisfied, unsatisfied, partial_failure }
    var action: Action
    var subject: String
    var quantity: Double?
    var value: Double?
    var currency: String?
    var payment_method: Payment?
    var outcome: Outcome?
    var reason: String?
    var meta: [String: JSONValue] = [:]
}

struct Temporal: Codable { var when: String?; var inferred_date: String? }
struct Location: Codable { var mentioned: String?; var inferred: String? }
struct Relationship: Codable { var entity1: String; var relation: String; var entity2: String }
