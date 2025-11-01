# Changelog

All notable changes to LogLineOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-11-01

### Added
- **EntityDetailView**: Fully implemented with comprehensive statistics
  - Total transactions and value display
  - Average transaction calculation
  - First and last seen dates
  - Complete transaction history
  - Color-coded event types
  - Visual statistics cards

- **DataExporter Service**: New export functionality
  - CSV export with proper escaping
  - JSON export with metadata
  - Summary statistics generation
  - File saving to temporary directory
  - Export from multiple views

- **Enhanced LedgerView**:
  - Full-text search functionality
  - Advanced filtering (Today, This Week, This Month, Custom Range)
  - Date range picker with calendar UI
  - Quick export to CSV/JSON
  - Improved visual design
  - Loading and error states
  - Result count indicators
  - Navigation to entity details

- **Enhanced QueryEngine**:
  - `allEntities()` method
  - `searchEvents(query:)` full-text search
  - `eventsInDateRange(from:to:)` date filtering
  - `topCustomers(limit:from:to:)` analytics
  - `purchasesFor(_:from:to:)` custom date ranges

- **Advanced QueryView**:
  - Flexible time period selection
  - Top customers report
  - Enhanced results display with averages
  - Custom date range pickers
  - Better error handling

- **Settings Screen** (NEW):
  - Extraction settings (Stub vs AI)
  - Clarification turn configuration
  - Privacy and analytics toggles
  - Security information viewer
  - System statistics display
  - All entities browser
  - Data management tools
  - About screen with app info

- **Database Enhancements**:
  - `allEventsForEntity(named:)` method
  - `allEntityNames()` distinct entity query
  - `searchEvents(query:)` with LIKE queries
  - `eventsInDateRange(start:end:)` filtering
  - `parseEventRow(stmt:)` helper for code reuse

- **UI Components**:
  - `EventRow` component for consistent event display
  - `StatItem` and `ResultRow` for statistics
  - `DateRangePickerSheet` for date selection
  - `AboutView` with feature highlights
  - `SecurityInfoView` with encryption details
  - `DataManagementView` for data operations

- **Tests**:
  - `QueryEngineTests` for date calculations
  - `DataExporterTests` for export validation
  - `EnhancedFeaturesTests` for UI features
  - 15+ new test cases

- **Documentation**:
  - `ENHANCEMENTS.md` comprehensive feature guide
  - This `CHANGELOG.md` file
  - Updated `README.md` with new features

### Changed
- **QueryViewModel**: Expanded with time periods and top customers
- **LedgerIndexSQLite**: Refactored with parseEventRow helper
- **LedgerEngine**: Added new query methods
- **LogLineOSApp**: Added Settings tab to main navigation
- **README.md**: Updated with enhancement highlights

### Improved
- Error handling throughout the app
- Loading states for all async operations
- Empty states with helpful messages
- Visual hierarchy and color coding
- Code reusability and organization
- Test coverage (from 2 to 5 test files)

### Fixed
- Code duplication in SQLite query parsing
- Inconsistent error messages
- Missing navigation links

## [1.0.0] - 2025-01-15

### Added
- Initial implementation from Blueprint specification
- Event-sourced ledger with HMAC-SHA256 security
- Natural language business event detection (PT/EN/ES)
- LLM-based data extraction with Gemini API
- Multi-turn clarification engine
- SwiftUI chat interface
- SQLite-based query engine
- Cryptographic receipts with Merkle trees
- NDJSON storage for events
- Daily Merkle root calculation
- Keychain integration for HMAC keys
- Business language detector
- Canonical data models
- Privacy features (PII hashing)
- OSLog integration
- Basic unit tests
- Comprehensive documentation (7 files)

### Core Features
- Chat view for natural language input
- Query view for customer lookups
- Ledger view for event browsing
- HMAC chain hashing
- Append-only ledger
- Deterministic JSON encoding
- Actor-based concurrency
- Async/await throughout

---

## Version History

- **1.1.0**: Enhanced features, UI improvements, analytics
- **1.0.0**: Initial Blueprint implementation

## Future Roadmap

### Planned for 1.2.0
- [ ] Data visualization with charts
- [ ] Transaction trend analysis
- [ ] Export to PDF
- [ ] Email export capability
- [ ] Cloud backup integration
- [ ] Advanced filtering options
- [ ] Bulk operations
- [ ] Import functionality

### Planned for 1.3.0
- [ ] Dark mode optimization
- [ ] Animations and transitions
- [ ] Haptic feedback
- [ ] Siri shortcuts
- [ ] Widget support
- [ ] Apple Watch companion
- [ ] iPad optimization
- [ ] Performance improvements

### Long-term Ideas
- [ ] Multi-user support
- [ ] Role-based access control
- [ ] Advanced analytics dashboard
- [ ] Machine learning predictions
- [ ] Internationalization improvements
- [ ] Voice input support
- [ ] Barcode scanning
- [ ] Receipt photo capture
