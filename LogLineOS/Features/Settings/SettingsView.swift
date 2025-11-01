import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var env: AppEnvironment
    @AppStorage("useStubExtractor") private var useStubExtractor = true
    @AppStorage("enableAnalytics") private var enableAnalytics = false
    @AppStorage("maxClarificationTurns") private var maxClarificationTurns = 2.0
    @State private var showingAbout = false
    @State private var showingDataManagement = false
    @State private var entities: [String] = []
    @State private var stats: SystemStats?
    
    var body: some View {
        NavigationView {
            Form {
                // Extraction Settings
                Section("Extraction") {
                    Toggle("Use Offline Mode (Stub Extractor)", isOn: $useStubExtractor)
                        .help("When enabled, uses sample data instead of AI extraction")
                    
                    Stepper("Max Clarification Turns: \(Int(maxClarificationTurns))", 
                           value: $maxClarificationTurns,
                           in: 0...5,
                           step: 1)
                }
                
                // Privacy Settings
                Section("Privacy & Security") {
                    Toggle("Enable Analytics", isOn: $enableAnalytics)
                        .help("Collect anonymous usage statistics")
                    
                    NavigationLink(destination: SecurityInfoView()) {
                        Label("Security Information", systemImage: "lock.shield")
                    }
                }
                
                // Data Management
                Section("Data") {
                    if let stats = stats {
                        VStack(alignment: .leading, spacing: 8) {
                            StatRow(label: "Total Events", value: "\(stats.totalEvents)")
                            StatRow(label: "Unique Entities", value: "\(stats.uniqueEntities)")
                            StatRow(label: "Database Size", value: stats.databaseSize)
                        }
                    }
                    
                    Button {
                        showingDataManagement = true
                    } label: {
                        Label("Manage Data", systemImage: "externaldrive")
                    }
                }
                
                // Entities
                Section("All Entities (\(entities.count))") {
                    ForEach(entities, id: \.self) { entity in
                        NavigationLink(destination: EntityDetailView(entityName: entity)
                            .environmentObject(env)) {
                            Text(entity)
                        }
                    }
                }
                
                // About
                Section {
                    Button {
                        showingAbout = true
                    } label: {
                        Label("About LogLineOS", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingDataManagement) {
                DataManagementView(env: env)
            }
        }
    }
    
    private func loadData() async {
        do {
            entities = try await env.queryEngine.allEntities()
            
            // Calculate basic stats
            let today = Date()
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: today) ?? today
            let events = try await env.ledgerEngine.eventsInDateRange(from: oneMonthAgo, to: today)
            
            stats = SystemStats(
                totalEvents: events.count,
                uniqueEntities: entities.count,
                databaseSize: "~\(events.count * 2) KB" // Rough estimate
            )
        } catch {
            // Handle error silently or show alert
        }
    }
}

struct SystemStats {
    let totalEvents: Int
    let uniqueEntities: Int
    let databaseSize: String
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct SecurityInfoView: View {
    var body: some View {
        List {
            Section("Encryption") {
                InfoRow(title: "Algorithm", value: "HMAC-SHA256")
                InfoRow(title: "Key Size", value: "256 bits")
                InfoRow(title: "Storage", value: "iOS Keychain")
            }
            
            Section("Integrity") {
                Text("All events are cryptographically signed using HMAC")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Chain hashing ensures tamper detection")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Daily Merkle roots provide audit trails")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Privacy") {
                Text("All data is stored locally on your device")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Optional PII hashing available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("No cloud backup unless explicitly enabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Security")
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("LogLineOS")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Natural-Language Business Ledger")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureItem(icon: "lock.shield", title: "Secure", 
                                   description: "HMAC-SHA256 encryption with iOS Keychain")
                        FeatureItem(icon: "globe", title: "Multi-language", 
                                   description: "Supports Portuguese, English, and Spanish")
                        FeatureItem(icon: "cpu", title: "AI-Powered", 
                                   description: "Optional LLM extraction with clarifications")
                        FeatureItem(icon: "chart.bar", title: "Analytics", 
                                   description: "Fast SQLite-based queries and aggregations")
                    }
                    .padding()
                    
                    Text("Built with SwiftUI and modern iOS technologies")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DataManagementView: View {
    let env: AppEnvironment
    @Environment(\.dismiss) var dismiss
    @State private var showingClearConfirmation = false
    @State private var showingExportSuccess = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Export") {
                    Button {
                        Task { await exportAllData() }
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("Danger Zone") {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Data?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    // Implementation would go here
                }
            } message: {
                Text("This will permanently delete all events and cannot be undone.")
            }
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                Button("OK") { }
            }
        }
    }
    
    private func exportAllData() async {
        // Get all events and export
        do {
            let start = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
            let events = try await env.ledgerEngine.eventsInDateRange(from: start, to: Date())
            
            let exporter = DataExporter()
            let content = try exporter.exportToJSON(events)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let filename = "logline_full_export_\(dateFormatter.string(from: Date()))"
            
            _ = try exporter.saveToFile(content: content, filename: filename, format: .json)
            showingExportSuccess = true
        } catch {
            // Handle error
        }
    }
}
