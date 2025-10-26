import SwiftUI

struct LedgerView: View {
    let env: AppEnvironment
    @State private var day = Date().dayKey
    @State private var items: [IndexedEvent] = []
    
    var body: some View {
        VStack {
            HStack {
                Text("Dia: \(day)")
                Spacer()
                Button("Atualizar") { Task { await load() } }
            }.padding([.horizontal, .top])
            List(items) { e in
                VStack(alignment: .leading) {
                    Text("\(e.action.uppercased()) • \(e.subject)").font(.headline)
                    Text("\(e.entityName ?? "-") • \(e.timestamp.formatted())")
                    if let v = e.value, let c = e.currency {
                        Text("Valor: \(c) \(String(format: "%.2f", v)) • Pagamento: \(e.payment ?? "-")")
                    }
                }
            }
        }
        .onAppear { Task { await load() } }
        .navigationTitle("Ledger")
    }
    
    private func load() async {
        if let rows = try? await env.ledgerEngine.eventsFor(day: day) {
            items = rows
        }
    }
}
