import SwiftUI
import OSLog

@main
struct LogLineOSApp: App {
    @StateObject private var env = AppEnvironment.bootstrap()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(env)
                .onAppear {
                    env.ledgerEngine.warmUp()
                }
        }
    }
}

private struct RootTabView: View {
    @EnvironmentObject var env: AppEnvironment
    
    var body: some View {
        TabView {
            ChatView(vm: .init(env: env))
                .tabItem { Label("Chat", systemImage: "ellipsis.bubble") }
            QueryView(vm: .init(env: env))
                .tabItem { Label("Queries", systemImage: "magnifyingglass") }
            LedgerView(env: env)
                .tabItem { Label("Ledger", systemImage: "list.bullet.rectangle") }
        }
    }
}
