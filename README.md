# LogLine-iOS

Natural-Language Business Ledger for iOS - An enterprise-grade iOS application implementing an event-sourced ledger system with natural language processing.

## 📋 Blueprint

This project is implemented from the comprehensive Blueprint specification located in [`Blueprint.md`](./Blueprint.md).

The Blueprint contains the complete architecture, code, and documentation for:
- Event-sourced ledger with HMAC security
- Natural language business event detection (PT/EN/ES)
- LLM-based data extraction with clarifications
- SwiftUI chat interface
- SQLite-based query engine
- Cryptographic receipts with Merkle trees

## 🚀 Implementation Status

✅ **Complete** - All source code has been implemented according to the Blueprint specification.

See [`IMPLEMENTATION.md`](./IMPLEMENTATION.md) for detailed setup instructions and documentation.

## 📁 Project Structure

```
LogLineOS/
├── App/                    # Application entry point
├── Features/               # SwiftUI views (Chat, Query, Ledger)
├── Services/              # Business logic
│   ├── Detection/         # Language detection
│   ├── Extraction/        # LLM extraction
│   ├── Clarification/     # Multi-turn clarification
│   ├── Ledger/           # Core ledger engine
│   ├── Query/            # Query engine
│   ├── Privacy/          # PII hashing
│   └── Util/             # Utilities
├── Config/               # Configuration
└── Tests/                # Unit tests
```

## 🛠 Quick Start

1. **Review the Blueprint**: Read [`Blueprint.md`](./Blueprint.md) to understand the system architecture
2. **Set up Xcode**: Follow the instructions in [`IMPLEMENTATION.md`](./IMPLEMENTATION.md)
3. **Build and Run**: Open in Xcode 15+ and run on iOS 17+ simulator or device

## 📖 Documentation

- **[Blueprint.md](./Blueprint.md)** - Complete system specification in Portuguese
- **[IMPLEMENTATION.md](./IMPLEMENTATION.md)** - Setup guide and technical documentation

## 🔑 Key Features

- 🔒 **Security**: HMAC-SHA256, Keychain storage, append-only ledger
- 🌐 **Multi-language**: Portuguese, English, Spanish support
- 🤖 **AI-Powered**: LLM extraction with Gemini API (optional)
- 📱 **Native iOS**: SwiftUI, async/await, iOS 17+
- 🔍 **Query Engine**: Fast SQLite-based aggregations
- 📊 **Observability**: OSLog integration throughout

## 💡 Usage Example

**Chat interface:**
```
User: "Amanda Barros comprou 2 camisetas"
App:  "Qual foi o valor total?"
User: "R$ 120 com Pix"
App:  "✅ Registrado! Event: evt:xyz... Merkle: abc..."
```

## 🧪 Testing

```bash
# In Xcode, press ⌘U to run tests
# Or use Swift Package Manager:
swift test
```

## 📄 License

See LICENSE file for details.

---

Built from the LogLineOS Blueprint specification.