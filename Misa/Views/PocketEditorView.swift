import SwiftData
import SwiftUI

struct PocketEditorView: View {
    let pocket: Pocket?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var pockets: [Pocket]

    @State private var name = ""
    @State private var emoji = ""
    @State private var colorHex = PocketColorPalette.default
    @State private var showValidationAlert = false
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appThemeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        sectionCard(title: "Pocket info") {
                            TextField("Pocket name", text: $name)
                                .textInputAutocapitalization(.words)
                                .padding(12)
                                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            TextField("Emoji (optional)", text: $emoji)
                                .padding(12)
                                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        sectionCard(title: "Color") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                                ForEach(PocketColorPalette.options) { option in
                                    Button {
                                        colorHex = option.hex
                                    } label: {
                                        Circle()
                                            .fill(option.color)
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(colorHex == option.hex ? 0.9 : 0.2), lineWidth: colorHex == option.hex ? 2.5 : 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button {
                            savePocket()
                        } label: {
                            Text(pocket == nil ? "Create Pocket" : "Save Changes")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(pocket == nil ? "New Pocket" : "Edit Pocket")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Pocket name required", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert("Could not save pocket", isPresented: saveErrorBinding) {
                Button("OK", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "Unknown error")
            }
            .onAppear {
                guard let pocket else { return }
                name = pocket.name
                emoji = pocket.emoji ?? ""
                colorHex = pocket.colorHex
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(cornerRadius: 18)
    }

    private func savePocket() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidationAlert = true
            return
        }

        if let pocket {
            pocket.name = trimmedName
            pocket.emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emoji
            pocket.colorHex = colorHex
        } else {
            let nextSortOrder = (pockets.map(\.sortOrder).max() ?? -1) + 1
            let createdPocket = Pocket(
                name: trimmedName,
                colorHex: colorHex,
                emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emoji,
                sortOrder: nextSortOrder,
                isHidden: false
            )
            modelContext.insert(createdPocket)
        }

        do {
            try modelContext.save()
            Haptics.saveImpact()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    saveErrorMessage = nil
                }
            }
        )
    }
}
