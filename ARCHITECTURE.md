# LogLineOS Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          LogLineOS App                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────┐  ┌───────────┐  ┌─────────────┐               │
│  │   Chat    │  │  Queries  │  │   Ledger    │  ← SwiftUI    │
│  │   View    │  │   View    │  │    View     │    Views      │
│  └─────┬─────┘  └─────┬─────┘  └──────┬──────┘               │
│        │              │                │                       │
│  ┌─────▼─────┐  ┌─────▼─────┐  ┌──────▼──────┐               │
│  │   Chat    │  │   Query   │  │  (direct)   │  ← ViewModels │
│  │ ViewModel │  │ ViewModel │  │             │               │
│  └─────┬─────┘  └─────┬─────┘  └──────┬──────┘               │
│        │              │                │                       │
│        └──────────────┼────────────────┘                       │
│                       │                                        │
│                ┌──────▼──────┐                                │
│                │     App     │  ← Dependency                  │
│                │ Environment │    Injection                   │
│                └──────┬──────┘                                │
│                       │                                        │
├───────────────────────┼────────────────────────────────────────┤
│                       │                                        │
│  ┌────────────────────┼────────────────────────────┐          │
│  │                    │  Service Layer             │          │
│  │                    │                            │          │
│  │  ┌─────────────────▼─────────────────┐          │          │
│  │  │ BusinessLanguageDetector          │          │          │
│  │  │ • PT/EN/ES pattern matching       │          │          │
│  │  └────────────┬──────────────────────┘          │          │
│  │               │                                  │          │
│  │  ┌────────────▼──────────────────────┐          │          │
│  │  │ LLMExtractor (Protocol)           │          │          │
│  │  │ ├─ GeminiExtractor (Gemini API)   │          │          │
│  │  │ └─ StubExtractor (Offline)        │          │          │
│  │  └────────────┬──────────────────────┘          │          │
│  │               │                                  │          │
│  │  ┌────────────▼──────────────────────┐          │          │
│  │  │ ClarifierEngine                   │          │          │
│  │  │ • Max 2 clarification turns       │          │          │
│  │  └────────────┬──────────────────────┘          │          │
│  │               │                                  │          │
│  │  ┌────────────▼──────────────────────┐          │          │
│  │  │ LedgerEngine (Actor)              │          │          │
│  │  │ ├─ HMAC signing                   │          │          │
│  │  │ ├─ NDJSON storage                 │          │          │
│  │  │ ├─ Chain hashing                  │          │          │
│  │  │ └─ Merkle root calculation        │          │          │
│  │  └────────────┬──────────────────────┘          │          │
│  │               │                                  │          │
│  │  ┌────────────▼──────────────────────┐          │          │
│  │  │ LedgerIndexSQLite                 │          │          │
│  │  │ • Fast queries                    │          │          │
│  │  │ • Aggregations                    │          │          │
│  │  └────────────┬──────────────────────┘          │          │
│  │               │                                  │          │
│  │  ┌────────────▼──────────────────────┐          │          │
│  │  │ QueryEngine                       │          │          │
│  │  │ • Transaction queries             │          │          │
│  │  │ • Date range filters              │          │          │
│  │  └───────────────────────────────────┘          │          │
│  │                                                  │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                        Storage Layer                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐        │
│  │  Keychain   │  │  File System │  │    SQLite      │        │
│  │             │  │              │  │                │        │
│  │ • HMAC Key  │  │ • NDJSON     │  │ • Event Index  │        │
│  │ (256-bit)   │  │ • Manifests  │  │ • Fast Queries │        │
│  └─────────────┘  └──────────────┘  └────────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Ingest Flow (Chat → Ledger)

```
User Input: "Amanda comprou 2 camisetas" (PT: "Amanda bought 2 shirts")
    │
    ▼
[BusinessLanguageDetector]
    │ isBusinessLanguage? → YES
    ▼
[LLMExtractor.extract()]
    │ Returns: ExtractionDraft
    │ • canonical: { entities: [{name: "Amanda"}], events: [...] }
    │ • incompleteFields: ["transaction_value", "payment_method"]
    ▼
[ClarifierEngine.nextQuestion()]
    │ Returns: "Qual foi o valor total?"
    ▼
User: "R$ 120 com Pix"
    │
    ▼
[LLMExtractor.merge()]
    │ Updates: value=120, currency=BRL, payment=pix
    │ incompleteFields: [] (complete!)
    ▼
[LedgerEngine.append()]
    │
    ├─→ [CanonicalJSON.encode()] → deterministic JSON
    ├─→ [HMACKeychain.hmac()] → row hash
    ├─→ Chain hash = HMAC(prev || rowHash)
    ├─→ Write NDJSON line
    ├─→ [LedgerIndexSQLite.index()] → insert to DB
    └─→ [Merkle.root()] → daily Merkle root
    │
    ▼
LedgerReceipt
    • eventId: "evt:uuid"
    • day: "2025-01-15"
    • eventHashHex: "abc123..."
    • chainHashHex: "def456..."
    • merkleRootHex: "789ghi..."
```

### 2. Query Flow (Query → Results)

```
User Input: "[Customer Name]" (e.g., "Amanda Barros")
    │
    ▼
[QueryEngine.purchasesFor()]
    │
    ├─→ Calculate month range (start, end)
    │
    ▼
[LedgerEngine.queryTransactions()]
    │
    ▼
[LedgerIndexSQLite.aggregateForEntity()]
    │
    ├─→ SQL: SELECT COUNT(*), SUM(value)
    │        FROM events
    │        WHERE entity_name = ?  -- parameterized
    │        AND ts BETWEEN start AND end
    │        AND action IN ('sale', 'payment')
    │
    ▼
Result: (count: 5, total: 1250.00)
```

### 3. Ledger View Flow

```
User Opens Ledger Tab
    │
    ▼
[LedgerView.onAppear]
    │
    ▼
[LedgerEngine.eventsFor(day)]
    │
    ▼
[LedgerIndexSQLite.eventsFor()]
    │
    ├─→ SQL: SELECT * FROM events
    │        WHERE day = '2025-01-15'
    │        ORDER BY ts DESC
    │
    ▼
[IndexedEvent] list
    │
    ▼
Display in List
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Security Layers                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 1: Key Management                                │
│  ┌───────────────────────────────────────────┐         │
│  │  Keychain (iOS Secure Enclave)            │         │
│  │  • HMAC-SHA256 256-bit key                │         │
│  │  • Automatically generated on first use   │         │
│  │  • Never leaves Keychain                  │         │
│  └───────────────────────────────────────────┘         │
│                      ▲                                  │
│                      │                                  │
│  Layer 2: Event Integrity                               │
│  ┌───────────────────┴───────────────────────┐         │
│  │  Per-Event HMAC                            │         │
│  │  • HMAC(canonical_json)                    │         │
│  │  • Stored in NDJSON: "row_hash"            │         │
│  └────────────────────────────────────────────┘         │
│                      ▲                                  │
│                      │                                  │
│  Layer 3: Chain Integrity                               │
│  ┌───────────────────┴───────────────────────┐         │
│  │  Chain Hashing                             │         │
│  │  • chain[n] = HMAC(chain[n-1] || row[n])  │         │
│  │  • Detects tampering with any event        │         │
│  └────────────────────────────────────────────┘         │
│                      ▲                                  │
│                      │                                  │
│  Layer 4: Daily Proofs                                  │
│  ┌───────────────────┴───────────────────────┐         │
│  │  Merkle Tree                               │         │
│  │  • Daily root from all event hashes        │         │
│  │  • Stored in manifest.json                 │         │
│  │  • Enables audit trails                    │         │
│  └────────────────────────────────────────────┘         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## File System Layout

```
Application Support/
├── ledger/
│   ├── 2025-01-15.ndjson          ← Events for 2025-01-15
│   ├── 2025-01-15.manifest.json   ← Daily Merkle root + metadata
│   ├── 2025-01-16.ndjson
│   ├── 2025-01-16.manifest.json
│   └── ...
│
└── ledger_index.sqlite            ← SQLite index
    ├── events table
    │   ├── id (PK)
    │   ├── ts (timestamp)
    │   ├── day
    │   ├── entity_name
    │   ├── action
    │   ├── subject
    │   ├── value
    │   ├── currency
    │   └── payment
    └── idx_events_entity_day
```

## NDJSON Event Format

```json
{
  "id": "evt:a1b2c3d4-e5f6-...",
  "timestamp": "2025-01-15T14:30:00Z",
  "traceId": "tr:biz:1705329000:a1b2c3d4",
  "spanId": "sp:event:0",
  "actor": "chat/user",
  "action": "sale",
  "subject": "camisetas",
  "canonical": {
    "entities": [
      {
        "name": "Amanda Barros",
        "type": "Person",
        "role": "customer"
      }
    ],
    "events": [
      {
        "action": "sale",
        "subject": "camisetas",
        "quantity": 2,
        "value": 120,
        "currency": "BRL",
        "payment_method": "pix",
        "outcome": "completed"
      }
    ],
    "temporal": {
      "when": "today",
      "inferred_date": "2025-01-15T00:00:00Z"
    }
  },
  "attrs": {
    "originalText": "Amanda Barros comprou 2 camisetas | R$ 120 com Pix",
    "temporal": "today",
    "location": ""
  },
  "row_hash": "abc123def456...",
  "chain_hash": "789ghi012jkl..."
}
```

## Component Responsibilities

| Component | Responsibility | Key Methods |
|-----------|---------------|-------------|
| `BusinessLanguageDetector` | Detect business language | `isBusinessLanguage(_:)` |
| `LLMExtractor` | Extract structured data | `extract(from:)`, `merge(...)` |
| `ClarifierEngine` | Generate clarification questions | `nextQuestion(for:)` |
| `LedgerEngine` | Append-only ledger operations | `append(...)`, `queryTransactions(...)` |
| `HMACKeychain` | HMAC key management | `ensureKey()`, `hmac(_:)` |
| `Merkle` | Merkle tree calculations | `root(leaves:)` |
| `LedgerIndexSQLite` | Fast queries | `aggregateForEntity(...)`, `eventsFor(day:)` |
| `QueryEngine` | Business query logic | `purchasesFor(_:monthOf:)` |
| `CanonicalJSON` | Deterministic JSON encoding | `encode(_:)` |
| `PIIHashing` | Privacy-preserving hashing | `saltedHash(_:salt:)` |

## Extension Points

To extend the system:

1. **New Event Types**: Add to `Event.Action` enum
2. **New Payment Methods**: Add to `Event.Payment` enum
3. **New LLM Provider**: Implement `LLMExtractor` protocol
4. **New Query Types**: Extend `QueryEngine`
5. **New UI Features**: Add to `Features/` with new ViewModels
6. **Background Tasks**: Add `BGProcessingTask` handlers
7. **Cloud Sync**: Implement sync service reading NDJSON files

---

For implementation details, see IMPLEMENTATION.md
For validation checklist, see VALIDATION.md
