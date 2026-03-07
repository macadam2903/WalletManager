import SwiftData
import SwiftUI

@main
struct MisaApp: App {
    @StateObject private var settingsStore = SettingsStore()
    private let sharedModelContainer: ModelContainer

    init() {
        sharedModelContainer = Self.makeModelContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .preferredColorScheme(settingsStore.preferredColorScheme)
                .id(settingsStore.appearanceMode.rawValue)
        }
        .modelContainer(sharedModelContainer)
    }
}

private extension MisaApp {
    static func makeModelContainer() -> ModelContainer {
        let fileManager = FileManager.default
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeDirectory = baseURL.appendingPathComponent("Misa", isDirectory: true)
        if !fileManager.fileExists(atPath: storeDirectory.path) {
            try? fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        }

        let storeURL = storeDirectory.appendingPathComponent("Misa.sqlite")
        let configuration = ModelConfiguration(url: storeURL)

        do {
            return try ModelContainer(for: Pocket.self, Transaction.self, Goal.self, configurations: configuration)
        } catch {
            // Do not delete the database on startup errors.
            // Keeping the original store prevents silent data loss during app updates.
            fatalError("Failed to create SwiftData container at \(storeURL.path): \(error.localizedDescription)")
        }
    }
}
