import Foundation
import SwiftUI

@MainActor
final class QueryViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var result: String = ""
    private let env: AppEnvironment
    init(env: AppEnvironment) { self.env = env }
    
    func run() {
        Task {
            do {
                let (count, total) = try await env.queryEngine.purchasesFor(name, monthOf: Date())
                result = "\(name): \(count) transações, total \(String(format: "R$ %.2f", total))"
            } catch {
                result = "Erro: \(error.localizedDescription)"
            }
        }
    }
}
