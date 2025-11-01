import SwiftUI

struct EntityDetailView: View {
    let entityName: String
    @EnvironmentObject var env: AppEnvironment
    @State private var events: [IndexedEvent] = []
    @State private var stats: EntityStats?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Statistics Card
                if let stats = stats {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 30) {
                            StatItem(label: "Total Transactions", value: "\(stats.totalCount)")
                            StatItem(label: "Total Value", value: stats.totalValue.currencyFormatted)
                            StatItem(label: "Avg. Transaction", value: stats.averageValue.currencyFormatted)
                        }
                        
                        if let firstSeen = stats.firstSeenDate {
                            Text("First seen: \(firstSeen.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let lastSeen = stats.lastSeenDate {
                            Text("Last seen: \(lastSeen.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                
                // Transaction History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else if events.isEmpty {
                        Text("No transactions found")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(events.prefix(20)) { event in
                            EventRowView(event: event)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle(entityName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadEntityData()
        }
    }
    
    private func loadEntityData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all events for this entity
            let allEvents = try await env.ledgerEngine.allEventsForEntity(named: entityName)
            events = allEvents
            
            // Calculate statistics
            let totalValue = allEvents.reduce(0.0) { $0 + ($1.value ?? 0) }
            let count = allEvents.count
            let average = count > 0 ? totalValue / Double(count) : 0
            
            let firstDate = allEvents.map(\.timestamp).min()
            let lastDate = allEvents.map(\.timestamp).max()
            
            stats = EntityStats(
                totalCount: count,
                totalValue: totalValue,
                averageValue: average,
                firstSeenDate: firstDate,
                lastSeenDate: lastDate
            )
        } catch {
            errorMessage = "Failed to load entity data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct EntityStats {
    let totalCount: Int
    let totalValue: Double
    let averageValue: Double
    let firstSeenDate: Date?
    let lastSeenDate: Date?
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

struct EventRowView: View {
    let event: IndexedEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.action.uppercased())
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(actionColor)
                    .cornerRadius(4)
                
                Text(event.subject)
                    .font(.headline)
                
                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let value = event.value, let currency = event.currency {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(currency) \(String(format: "%.2f", value))")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let payment = event.payment {
                        Text(payment)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
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

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: self)) ?? "R$ \(String(format: "%.2f", self))"
    }
}
