# Quick Start Guide

## 🎯 What is LogLineOS?

LogLineOS is a production-ready iOS app that turns natural language business conversations into a secure, tamper-proof ledger system. Say "Amanda bought 2 shirts for $120 with Pix" and it automatically:
- Extracts structured data (who, what, how much, how paid)
- Asks for missing details
- Stores events with cryptographic receipts
- Makes them searchable

## 📱 For First-Time Users

### The 5-Minute Setup

1. **Prerequisites**
   - macOS with Xcode 15+
   - iOS 17+ simulator or device

2. **Quick Setup**
   ```bash
   # Clone the repository
   git clone https://github.com/danvoulez/LogLine-iOS.git
   cd LogLine-iOS
   
   # Read the instructions
   cat IMPLEMENTATION.md
   ```

3. **In Xcode**
   - File → New → Project → iOS App
   - Name it "LogLineOS"
   - Delete template files
   - Drag `LogLineOS` folder into project
   - Press ⌘R to run!

4. **Try It Out**
   - Go to Chat tab
   - Type: "Maria Silva comprou 3 livros"
   - Answer the questions
   - See the receipt!

## 📚 Key Documents

| Document | Purpose | When to Read |
|----------|---------|--------------|
| `README.md` | Overview & quick links | Start here |
| `IMPLEMENTATION.md` | Detailed setup guide | Setting up project |
| `Blueprint.md` | Complete specification (PT) | Understanding architecture |
| `VALIDATION.md` | Implementation checklist | Verifying completeness |
| This file | Quick reference | Need fast answers |

## 🎨 Features at a Glance

### Chat Tab
- Type business events in natural language (Portuguese, English, Spanish)
- System asks clarifying questions
- Get cryptographic receipts

### Query Tab
- Enter customer name
- See transaction count and total for current month

### Ledger Tab
- View today's events
- See all transaction details

## 🔧 Common Tasks

### Change the LLM Provider
Edit `AppEnvironment.swift`:
```swift
let extractor: LLMExtractor = StubExtractor() // No API needed
// or
let extractor: LLMExtractor = GeminiExtractor() // Needs API key
```

### Add Gemini API Key
1. Get key from https://makersuite.google.com/app/apikey
2. Open `LogLineOS/Config/Secrets.plist`
3. Replace `YOUR_KEY_HERE` with actual key
4. Rebuild

### Run Tests
- In Xcode: Press ⌘U
- Or: Product → Test

### View Logs
In Xcode:
- While running: Console shows OSLog output
- Categories: app, ingest, ledger, extract, query, security

### Access Stored Data
Ledger files are in:
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE]/
  data/Containers/Data/Application/[APP]/
  Library/Application Support/ledger/
```

## 🐛 Troubleshooting

### "Cannot find module OSLog"
→ You're trying to build with SPM on Linux. Use Xcode on macOS.

### "No GEMINI_API_KEY; falling back to stub"
→ This is normal! The stub works fine for development.

### Build fails with missing files
→ Make sure all files in `LogLineOS` are added to the Xcode target.

### Keychain errors in Simulator
→ Reset simulator: Device → Erase All Content and Settings

## 📖 Architecture Overview

```
User Input
    ↓
BusinessLanguageDetector (is it a business event?)
    ↓
LLMExtractor (extract structured data)
    ↓
ClarifierEngine (ask for missing fields)
    ↓
LedgerEngine (append to ledger)
    ├─ HMAC signing
    ├─ NDJSON storage
    ├─ SQLite indexing
    └─ Merkle root calculation
    ↓
LedgerReceipt (cryptographic proof)
```

## 💡 Examples

### Business Event Examples
```
Portuguese:
- "João Santos comprou 5 camisetas por R$ 250 no cartão"
- "Cliente devolveu calça jeans, crédito da loja"
- "Vendeu ontem para aquela morena de Santos"

English:
- "Customer bought 3 books for $45 with credit card"
- "Amanda returned tight pants, store credit"
- "Sold yesterday to the tall guy from accounting"

Spanish:
- "Cliente compró 2 zapatos por $80 con tarjeta"
- "Vendió ayer al cliente de Madrid"
```

### Query Examples
```
- "Amanda Barros" → Shows her transactions this month
- "João Santos" → Shows his activity
```

## 🚀 Next Steps

1. ✅ Set up the project (follow IMPLEMENTATION.md)
2. ✅ Run and test the app
3. 📚 Read Blueprint.md to understand the full architecture
4. 🔧 Customize for your needs
5. 🎨 Add your own features
6. 🌟 Deploy to production (with proper security review)

## 🆘 Need Help?

1. Check IMPLEMENTATION.md for detailed instructions
2. Review VALIDATION.md to see what's implemented
3. Read Blueprint.md for architectural details
4. Check issues on GitHub
5. Review the code - it's well-commented!

## 📝 License

See LICENSE file for details.

---

**Remember**: This is a starter kit. Review security settings, adjust for your use case, and test thoroughly before production use!
