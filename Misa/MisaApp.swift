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
        let storeURL = baseURL.appendingPathComponent("Misa.sqlite")
        let configuration = ModelConfiguration(url: storeURL)

        do {
            return try ModelContainer(for: Pocket.self, Transaction.self, Goal.self, configurations: configuration)
        } catch {
            removeStoreFiles(at: storeURL)

            do {
                return try ModelContainer(for: Pocket.self, Transaction.self, Goal.self, configurations: configuration)
            } catch {
                fatalError("Failed to create SwiftData container: \(error.localizedDescription)")
            }
        }
    }

    static func removeStoreFiles(at storeURL: URL) {
        let fileManager = FileManager.default
        let urlsToDelete = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in urlsToDelete where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}
