# LogLineOS - Natural-Language Business Ledger for iOS

This is an enterprise-grade iOS application implementing a Natural-Language Business Ledger system, built from the Blueprint specification.

## Features

- **Event-Sourced Ledger**: Append-only with HMAC security and daily Merkle trees
- **Natural Language Processing**: Detects business language in PT/EN/ES
- **LLM Extraction**: Pluggable client with Gemini API example
- **Clarification Loop**: Interactive 2-turn clarification process
- **NDJSON Storage**: With SQLite indexing for fast queries
- **Privacy First**: HMAC with Keychain, PII hashing
- **SwiftUI Interface**: Chat, Queries, and Ledger views

## Project Structure

```
LogLineOS/
├── App/                    # Application entry point and environment
├── Features/               # UI features (Chat, Query, Ledger)
├── Services/              # Business logic services
│   ├── Detection/         # Language detection
│   ├── Extraction/        # LLM extraction
│   ├── Clarification/     # Multi-turn clarification
│   ├── Ledger/           # Core ledger engine
│   ├── Query/            # Query engine
│   ├── Privacy/          # PII hashing
│   └── Util/             # Utility functions
├── Config/               # Configuration files
└── Tests/                # Unit tests
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup Instructions

### 1. Create Xcode Project

Since this repository contains the source code structure but not the Xcode project file, you need to create an iOS App project in Xcode:

1. Open Xcode
2. Create a new project: File → New → Project
3. Choose "iOS" → "App"
4. Set the following:
   - Product Name: `LogLineOS`
   - Organization Identifier: `com.yourorg` (or your preference)
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `iOS 17.0`
5. Choose a location OUTSIDE this repository initially

### 2. Add Source Files to Xcode

1. In the Xcode project navigator, delete the default files (ContentView.swift, etc.)
2. Drag the entire `LogLineOS` folder from this repository into your Xcode project
3. In the dialog, choose:
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Add to target: LogLineOS

### 3. Configure Build Settings

1. Select your project in the navigator
2. Select the LogLineOS target
3. Go to "Signing & Capabilities"
4. Configure your development team

### 4. Configure Secrets (Optional)

If you want to use the Gemini API for real extraction:

1. Open `LogLineOS/Config/Secrets.plist`
2. Replace `YOUR_KEY_HERE` with your actual Gemini API key
3. Ensure this file is added to your Xcode project
4. **Important**: Add `Secrets.plist` to your `.gitignore` to avoid committing secrets

If you don't configure a Gemini API key, the app will use the `StubExtractor` which returns sample data.

### 5. Link SQLite

The project uses SQLite3 which is included in iOS. Make sure the following framework is linked:
- `libsqlite3.tbd` (should be automatically linked)

### 6. Build and Run

1. Select a simulator or device
2. Press `⌘R` to build and run

## Quick Start with Swift Package Manager

Alternatively, you can use Swift Package Manager for development (though you'll still need Xcode to create a proper iOS app target):

```bash
swift build
swift test
```

Note: This approach is limited as iOS apps require proper bundle resources and entitlements.

## Usage

### Chat Interface

The Chat tab allows you to input business events in natural language:

**Example inputs:**
- "Amanda Barros comprou 2 camisetas por R$ 120 com Pix"
- "Cliente devolveu calça jeans apertada, crédito da loja"
- "Vendeu ontem para aquela morena de São Paulo"

The app will:
1. Detect it's business language
2. Extract structured data
3. Ask for missing information (2-turn max)
4. Commit to the ledger with cryptographic receipt

### Query Interface

Query customer transactions:

1. Enter customer name (e.g., "Amanda Barros")
2. Click "Run Query"
3. View transaction count and total for current month

### Ledger Interface

View all events for today:
- Shows entity names, actions, subjects, values
- Sorted by timestamp (newest first)

## Architecture Highlights

### Security
- HMAC-SHA256 with 256-bit keys stored in Keychain
- Append-only ledger (no modifications/deletions)
- Daily Merkle trees for tamper detection
- PII hashing with salts

### Performance
- SQLite with WAL mode for concurrent reads
- Async/await throughout
- Actor-based ledger engine for thread safety
- Incremental Merkle root calculation

### Privacy
- No PII sent to LLM if using StubExtractor
- Hashed entity references available
- Local-first data storage

### Observability
- OSLog integration throughout
- Structured logging by category
- Trace IDs and Span IDs in events

## Development

### Running Tests

In Xcode:
1. Press `⌘U` to run all tests
2. Or: Product → Test

Tests cover:
- Canonical model validation
- Business language detection
- Stub extraction logic
- Incomplete field detection

### Extending the System

The architecture is designed for extensibility:

- **Add new extractors**: Implement `LLMExtractor` protocol
- **Add new event types**: Extend `Event.Action` enum
- **Add new entity types**: Extend `Entity.EType` enum
- **Add custom queries**: Extend `QueryEngine`

## Production Considerations

### Recommended Enhancements

1. **Background Tasks**: Use `BGProcessingTask` for daily Merkle finalization
2. **Cloud Sync**: Optional backup to secure cloud storage
3. **MDM Integration**: For enterprise deployment
4. **Siri Integration**: Voice-based event logging
5. **i18n**: Full localization support
6. **Retention Policies**: Configurable data retention
7. **Audit Export**: Export capabilities for compliance

### Security Hardening

- Enable App Transport Security (ATS)
- Implement certificate pinning for API calls
- Use App Groups for shared keychain access (if needed)
- Consider biometric authentication for sensitive operations

## Troubleshooting

### Build Errors

**"Cannot find type 'Canonical' in scope"**
- Ensure all files in `LogLineOS/Services/Ledger/` are added to the target

**"No such module 'OSLog'"**
- Ensure iOS deployment target is set to iOS 17.0+

**SQLite errors**
- Verify `libsqlite3.tbd` is linked in Build Phases

### Runtime Issues

**"No GEMINI_API_KEY; falling back to stub"**
- This is expected if you haven't configured the API key
- The app will use sample data from `StubExtractor`

**Keychain access errors on Simulator**
- Reset the simulator: Device → Erase All Content and Settings

## License

This implementation follows the Blueprint specification. Adjust licensing as needed for your organization.

## Credits

Built from the Blueprint specification for LogLineOS - Natural-Language Business Ledger.

---

**Note**: This is a production-ready starter kit. Review and adjust security settings, API keys, and privacy policies according to your specific requirements before deploying to production.
