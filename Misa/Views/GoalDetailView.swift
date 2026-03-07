import SwiftData
import SwiftUI

struct GoalDetailView: View {
    let goal: Goal

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
    @State private var showDeleteConfirmation = false

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
                                ForEach(availablePockets) { pocket in
                                    Text("\(pocket.emoji ?? "💼") \(pocket.name)")
                                        .tag("pocket:\(pocket.id.uuidString)")
                                }
                            }
                            .pickerStyle(.menu)

                            Toggle("Include scheduled transactions", isOn: $includePendingTransactions)
                                .disabled(linkedPocketSelection == "none")
                        }

                        sectionCard(title: "Deadline") {
                            Toggle("Add deadline", isOn: $hasDeadline)

                            if hasDeadline {
                                DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                            }
                        }

                        Button {
                            saveChanges()
                        } label: {
                            Text("Save Changes")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .disabled(!canSave)

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Goal")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Goal Details")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid goal", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please provide a name and a target amount greater than zero.")
            }
            .alert("Delete goal?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteGoal()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .onAppear {
                name = goal.name
                targetAmountText = String(goal.targetAmount)
                currentAmountText = String(goal.currentAmount)
                if goal.useAllPockets {
                    linkedPocketSelection = "all"
                } else if let linkedPocketID = goal.linkedPocketID {
                    linkedPocketSelection = "pocket:\(linkedPocketID.uuidString)"
                } else {
                    linkedPocketSelection = "none"
                }
                includePendingTransactions = goal.includePendingTransactions
                hasDeadline = goal.deadline != nil
                deadline = goal.deadline ?? Date.now
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

    private func saveChanges() {
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
        let resolvedCurrentAmount: Double = {
            if includeAllPockets {
                return visiblePockets.reduce(0) { partialResult, pocket in
                    partialResult + (includePendingTransactions ? pocket.projectedBalance : pocket.balance)
                }
            }

            guard let resolvedLinkedPocketID else { return parsedCurrentAmount }
            guard let linkedPocket = availablePockets.first(where: { $0.id == resolvedLinkedPocketID }) else { return parsedCurrentAmount }
            return includePendingTransactions ? linkedPocket.projectedBalance : linkedPocket.balance
        }()

        goal.name = trimmedName
        goal.targetAmount = targetAmount
        goal.currentAmount = resolvedCurrentAmount
        goal.linkedPocketID = resolvedLinkedPocketID
        goal.useAllPockets = includeAllPockets
        goal.includePendingTransactions = includePendingTransactions
        goal.deadline = hasDeadline ? deadline : nil

        try? modelContext.save()
        Haptics.saveImpact()
        dismiss()
    }

    private func deleteGoal() {
        modelContext.delete(goal)
        try? modelContext.save()
        dismiss()
    }

    private var selectedLinkedPocketID: UUID? {
        guard linkedPocketSelection.hasPrefix("pocket:") else { return nil }
        return UUID(uuidString: String(linkedPocketSelection.dropFirst("pocket:".count)))
    }

    private var visiblePockets: [Pocket] {
        pockets.orderedPockets(includeHidden: false)
    }

    private var availablePockets: [Pocket] {
        var result = visiblePockets
        if let linkedPocketID = goal.linkedPocketID,
           let linkedPocket = pockets.first(where: { $0.id == linkedPocketID }),
           result.contains(where: { $0.id == linkedPocketID }) == false {
            result.append(linkedPocket)
        }
        return result.orderedPockets()
    }
}
