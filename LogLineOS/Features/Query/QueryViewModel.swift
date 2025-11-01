import Foundation
import SwiftUI

@MainActor
final class QueryViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var result: String = ""
    @Published var timePeriod: TimePeriod = .thisMonth
    @Published var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var customEndDate = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var transactionCount: Int = 0
    @Published var totalValue: Double = 0
    @Published var topCustomers: [(name: String, count: Int, total: Double)] = []
    
    private let env: AppEnvironment
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case custom = "Custom Range"
    }
    
    init(env: AppEnvironment) { self.env = env }
    
    func run() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let (start, end) = getDateRange()
                let (count, total) = try await env.queryEngine.purchasesFor(name, from: start, to: end)
                
                transactionCount = count
                totalValue = total
                result = "\(name): \(count) transaction(s), total \(String(format: "R$ %.2f", total))"
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
                result = ""
            }
            
            isLoading = false
        }
    }
    
    func loadTopCustomers() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let cal = Calendar.current
                let start = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
                let end = cal.date(byAdding: .month, value: 1, to: start)!
                
                topCustomers = try await env.queryEngine.topCustomers(limit: 10, from: start, to: end)
            } catch {
                errorMessage = "Error loading top customers: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    private func getDateRange() -> (Date, Date) {
        let cal = Calendar.current
        let now = Date()
        
        switch timePeriod {
        case .thisWeek:
            let start = cal.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
            
        case .thisMonth:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let end = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
            
        case .lastMonth:
            let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return (lastMonthStart, thisMonthStart)
            
        case .last3Months:
            let start = cal.date(byAdding: .month, value: -3, to: now) ?? now
            return (start, now)
            
        case .custom:
            return (customStartDate, customEndDate)
        }
    }
}
