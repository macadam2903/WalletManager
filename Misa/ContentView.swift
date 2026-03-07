import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore())
        .modelContainer(for: [Pocket.self, Transaction.self, Goal.self], inMemory: true)
}
