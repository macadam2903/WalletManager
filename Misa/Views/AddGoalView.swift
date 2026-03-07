import SwiftData
import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var pockets: [Pocket]

    @State private var name = ""
    @State private var targetAmountText = ""
    @State private var currentAmountText = ""
    @State private var linkedPocketSelection = "none"
    @State private var includePendingTransactions = false
    @State private var hasDeadline = false
    @State private var deadline = Date.now

    @State private var showValidationAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appThemeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        sectionCard(title: "Goal") {
                            TextField("Goal name", text: $name)
                                .textInputAutocapitalization(.words)
                                .padding(12)
                                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            TextField("Target amount", text: $targetAmountText)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            TextField("Current amount", text: $currentAmountText)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        sectionCard(title: "Linked Pocket") {
                            Picker("Pocket", selection: $linkedPocketSelection) {
                                Text("None").tag("none")
                                Text("All pockets").tag("all")
                                ForEach(visiblePockets) { pocket in
                                    Text("\(pocket.emoji ?? "💼") \(pocket.name)")
                                        .tag("pocket:\(pocket.id.uuidString)")
                                }
                            }
                            .pickerStyle(.menu)

                            Toggle("Include scheduled transactions", isOn: $includePendingTransactions)
                                .disabled(linkedPocketSelection == "none")

                            Text("If linked, progress uses the selected source balance.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        sectionCard(title: "Deadline") {
                            Toggle("Add deadline", isOn: $hasDeadline)

                            if hasDeadline {
                                DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                            }
                        }

                        Button {
                            saveGoal()
                        } label: {
                            Text("Save Goal")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .disabled(!canSave)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid goal", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please provide a name and a target amount greater than zero.")
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

    private var parsedTargetAmount: Double? {
        parseAmount(targetAmountText)
    }

    private var parsedCurrentAmount: Double {
        parseAmount(currentAmountText) ?? 0
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (parsedTargetAmount ?? 0) > 0
    }

    private func parseAmount(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func saveGoal() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty,
              let targetAmount = parsedTargetAmount,
              targetAmount > 0
        else {
            showValidationAlert = true
            return
        }

        let resolvedLinkedPocketID = selectedLinkedPocketID
        let includeAllPockets = linkedPocketSelection == "all"
        let linkedPocketBalance: Double? = {
            if includeAllPockets {
                return visiblePockets.reduce(0) { partialResult, pocket in
                    partialResult + (includePendingTransactions ? pocket.projectedBalance : pocket.balance)
                }
            }

            guard let resolvedLinkedPocketID else { return nil }
            guard let linkedPocket = visiblePockets.first(where: { $0.id == resolvedLinkedPocketID }) else { return nil }
            return includePendingTransactions ? linkedPocket.projectedBalance : linkedPocket.balance
        }()

        let currentAmount = linkedPocketBalance ?? parsedCurrentAmount

        let goal = Goal(
            name: trimmedName,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            deadline: hasDeadline ? deadline : nil,
            linkedPocketID: resolvedLinkedPocketID,
            useAllPockets: includeAllPockets,
            includePendingTransactions: includePendingTransactions
        )

        modelContext.insert(goal)
        try? modelContext.save()

        Haptics.saveImpact()
        dismiss()
    }

    private var selectedLinkedPocketID: UUID? {
        guard linkedPocketSelection.hasPrefix("pocket:") else { return nil }
        return UUID(uuidString: String(linkedPocketSelection.dropFirst("pocket:".count)))
    }

    private var visiblePockets: [Pocket] {
        pockets.orderedPockets(includeHidden: false)
    }
}
