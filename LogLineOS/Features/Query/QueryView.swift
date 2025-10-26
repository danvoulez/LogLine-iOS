import SwiftUI

struct QueryView: View {
    @ObservedObject var vm: QueryViewModel
    var body: some View {
        Form {
            Section("Customer") {
                TextField("e.g., Amanda Barros", text: $vm.name)
            }
            Button("Run Query") { vm.run() }.disabled(vm.name.isEmpty)
            if !vm.result.isEmpty {
                Section("Result") { Text(vm.result) }
            }
        }
        .navigationTitle("Queries")
    }
}
