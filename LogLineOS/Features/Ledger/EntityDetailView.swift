import SwiftUI

// EntityDetailView - placeholder for future implementation
struct EntityDetailView: View {
    let entityName: String
    
    var body: some View {
        VStack {
            Text("Details for: \(entityName)")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle(entityName)
    }
}
