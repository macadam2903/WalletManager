import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date) private var transactions: [Transaction]

    @State private var hasRefreshedPendingState = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            PocketsView()
                .tabItem {
                    Label("Pockets", systemImage: "wallet.pass")
                }

            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            guard !hasRefreshedPendingState else { return }
            hasRefreshedPendingState = true
            refreshPendingStates()
        }
    }

    private func refreshPendingStates() {
        let now = Date.now
        var hasChanges = false

        for transaction in transactions {
            let shouldBePending = transaction.date > now
            if transaction.isPending != shouldBePending {
                transaction.isPending = shouldBePending
                hasChanges = true
            }
        }

        guard hasChanges else { return }
        try? modelContext.save()
    }
}
