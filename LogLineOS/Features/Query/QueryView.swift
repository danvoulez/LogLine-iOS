import SwiftUI

struct QueryView: View {
    @ObservedObject var vm: QueryViewModel
    
    var body: some View {
        NavigationView {
            Form {
                // Entity Query
                Section("Entity Query") {
                    TextField("Customer name (e.g., Amanda Barros)", text: $vm.name)
                    
                    Picker("Time Period", selection: $vm.timePeriod) {
                        ForEach(QueryViewModel.TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    
                    if vm.timePeriod == .custom {
                        DatePicker("From", selection: $vm.customStartDate, displayedComponents: .date)
                        DatePicker("To", selection: $vm.customEndDate, displayedComponents: .date)
                    }
                    
                    Button("Run Query") {
                        vm.run()
                    }
                    .disabled(vm.name.isEmpty)
                }
                
                // Results
                if vm.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if let error = vm.errorMessage {
                    Section("Error") {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } else if !vm.result.isEmpty {
                    Section("Results") {
                        VStack(alignment: .leading, spacing: 12) {
                            ResultRow(label: "Entity", value: vm.name)
                            ResultRow(label: "Transactions", value: "\(vm.transactionCount)")
                            ResultRow(label: "Total Value", value: vm.totalValue.currencyFormatted)
                            
                            if vm.transactionCount > 0 {
                                let avg = vm.totalValue / Double(vm.transactionCount)
                                ResultRow(label: "Average", value: avg.currencyFormatted)
                            }
                        }
                    }
                }
                
                // Top Customers
                Section {
                    Button {
                        vm.loadTopCustomers()
                    } label: {
                        Label("Show Top Customers", systemImage: "chart.bar.fill")
                    }
                }
                
                if !vm.topCustomers.isEmpty {
                    Section("Top Customers This Month") {
                        ForEach(Array(vm.topCustomers.enumerated()), id: \.offset) { index, customer in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(customer.name)
                                        .font(.headline)
                                    Text("\(customer.count) transactions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(customer.total.currencyFormatted)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Queries")
        }
    }
}

struct ResultRow: View {
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
