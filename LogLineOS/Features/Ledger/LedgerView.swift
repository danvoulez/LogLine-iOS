import SwiftUI

struct LedgerView: View {
    let env: AppEnvironment
    @State private var items: [IndexedEvent] = []
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .today
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingExportSheet = false
    @State private var showingFilterSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    enum FilterMode: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case custom = "Custom Range"
    }
    
    var filteredItems: [IndexedEvent] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { event in
            event.entityName?.localizedCaseInsensitiveContains(searchText) == true ||
            event.subject.localizedCaseInsensitiveContains(searchText) ||
            event.action.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search...", text: $searchText)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Menu {
                        Picker("Filter", selection: $filterMode) {
                            ForEach(FilterMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                    
                    Menu {
                        Button {
                            Task { await exportData(format: .csv) }
                        } label: {
                            Label("Export CSV", systemImage: "doc.text")
                        }
                        
                        Button {
                            Task { await exportData(format: .json) }
                        } label: {
                            Label("Export JSON", systemImage: "doc.badge.gearshape")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                    }
                }
                .padding()
                
                // Filter indicator
                if filterMode != .today {
                    HStack {
                        Text(filterModeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if filterMode == .custom {
                            Button("Change Dates") {
                                showingFilterSheet = true
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Content
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await load() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "No transactions found" : "No results for '\(searchText)'")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            Text("\(filteredItems.count) transaction(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(filteredItems) { event in
                            NavigationLink(destination: EntityDetailView(entityName: event.entityName ?? "Unknown")
                                .environmentObject(env)) {
                                EventRow(event: event)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ledger")
            .onChange(of: filterMode) { _ in
                Task { await load() }
            }
            .task {
                await load()
            }
            .sheet(isPresented: $showingFilterSheet) {
                DateRangePickerSheet(startDate: $startDate, endDate: $endDate) {
                    Task { await load() }
                }
            }
            .alert("Export Successful", isPresented: $showingExportSheet) {
                Button("OK") { }
            } message: {
                Text("Data has been exported successfully")
            }
        }
    }
    
    private var filterModeDescription: String {
        switch filterMode {
        case .today:
            return "Today: \(Date().dayKey)"
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        case .custom:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    private func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            switch filterMode {
            case .today:
                items = try await env.ledgerEngine.eventsFor(day: Date().dayKey)
            case .week:
                let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                items = try await env.ledgerEngine.eventsInDateRange(from: start, to: Date())
            case .month:
                let start = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                items = try await env.ledgerEngine.eventsInDateRange(from: start, to: Date())
            case .custom:
                items = try await env.ledgerEngine.eventsInDateRange(from: startDate, to: endDate)
            }
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func exportData(format: ExportFormat) async {
        let exporter = DataExporter()
        
        do {
            let content: String
            switch format {
            case .csv:
                content = try exporter.exportToCSV(filteredItems)
            case .json:
                content = try exporter.exportToJSON(filteredItems)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let filename = "ledger_export_\(dateFormatter.string(from: Date()))"
            
            _ = try exporter.saveToFile(content: content, filename: filename, format: format)
            showingExportSheet = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}

struct EventRow: View {
    let event: IndexedEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.action.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(actionColor)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(event.subject)
                    .font(.headline)
                
                if let entityName = event.entityName {
                    Text(entityName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let value = event.value, let currency = event.currency {
                    HStack {
                        Text("\(currency) \(String(format: "%.2f", value))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let payment = event.payment {
                            Text("• \(payment)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var actionColor: Color {
        switch event.action.lowercased() {
        case "sale": return .green
        case "purchase": return .blue
        case "return": return .orange
        case "payment": return .purple
        default: return .gray
        }
    }
}

struct DateRangePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}
