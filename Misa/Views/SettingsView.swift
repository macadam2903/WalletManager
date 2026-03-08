import SwiftData
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.modelContext) private var modelContext

    @Query private var pockets: [Pocket]
    @Query private var transactions: [Transaction]
    @Query private var goals: [Goal]

    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appThemeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        sectionCard(title: "Appearance") {
                            Toggle("Dark Mode", isOn: darkModeBinding)
                        }

                        sectionCard(title: "Currency") {
                            Picker("Currency", selection: $settings.currency) {
                                ForEach(CurrencyOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        sectionCard(title: "App") {
                            HStack {
                                Text("Version")
                                Spacer()
                                Text(appVersion)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        sectionCard(title: "Danger Zone") {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete all data")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(20)
                    
                    VStack(spacing: 6) {
                        Text("Készítette Macza Ádám")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Link("GitHub", destination: URL(string: "https://github.com/macadam2903/WalletManager")!)
                            .font(.footnote)
                            .foregroundStyle(.blue)
                        Link("Instagram", destination: URL(string: "https://www.instagram.com/macadam0329/")!)
                            .font(.footnote)
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    
                }
            }
            .navigationTitle("Settings")
            .alert("Delete all data?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all pockets, transactions and goals.")
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(cornerRadius: 18)
    }

    private var darkModeBinding: Binding<Bool> {
        Binding(
            get: { settings.appearanceMode == .dark },
            set: { settings.appearanceMode = $0 ? .dark : .light }
        )
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func deleteAllData() {
        for transaction in transactions {
            modelContext.delete(transaction)
        }

        for pocket in pockets {
            modelContext.delete(pocket)
        }

        for goal in goals {
            modelContext.delete(goal)
        }

        try? modelContext.save()
    }
}
