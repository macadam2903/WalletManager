import SwiftData
import SwiftUI

struct EditTransactionView: View {
    enum TransactionType: String, CaseIterable, Identifiable {
        case income
        case expense

        var id: String { rawValue }

        var title: String {
            switch self {
            case .income:
                return "Income (+)"
            case .expense:
                return "Expense (-)"
            }
        }

        var isIncome: Bool {
            self == .income
        }
    }

    let transaction: Transaction

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var pockets: [Pocket]

    @State private var selectedPocketID: UUID?
    @State private var amountText = ""
    @State private var name = ""
    @State private var descriptionText = ""
    @State private var selectedType: TransactionType = .expense
    @State private var transactionDate = Date.now

    @State private var showValidationAlert = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appThemeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        sectionCard(title: "Pocket") {
                            Picker("Pocket", selection: pocketSelection) {
                                ForEach(availablePockets) { pocket in
                                    Text("\(pocket.emoji ?? "💼") \(pocket.name)")
                                        .tag(pocket.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        sectionCard(title: "Details") {
                            VStack(spacing: 12) {
                                TextField("Name", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .padding(12)
                                    .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                                TextField("Amount", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                                TextEditor(text: $descriptionText)
                                    .frame(minHeight: 90)
                                    .padding(8)
                                    .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        sectionCard(title: "Type & Date") {
                            VStack(spacing: 12) {
                                Picker("Type", selection: $selectedType) {
                                    ForEach(TransactionType.allCases) { type in
                                        Text(type.title).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)

                                DatePicker("Date", selection: $transactionDate, displayedComponents: [.date])
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
                            Text("Delete Transaction")
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
            .navigationTitle("Transaction Details")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid transaction", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please provide a name, amount and pocket.")
            }
            .alert("Delete transaction?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteTransaction()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .onAppear {
                selectedPocketID = transaction.pocket.id
                amountText = String(transaction.amount)
                name = transaction.name
                descriptionText = transaction.transactionDescription ?? ""
                selectedType = transaction.isIncome ? .income : .expense
                transactionDate = transaction.date
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

    private var pocketSelection: Binding<UUID> {
        Binding {
            selectedPocketID ?? transaction.pocket.id
        } set: { newValue in
            selectedPocketID = newValue
        }
    }

    private var selectedPocket: Pocket? {
        guard let selectedPocketID else { return nil }
        return availablePockets.first(where: { $0.id == selectedPocketID })
    }

    private var availablePockets: [Pocket] {
        var result = pockets.orderedPockets(includeHidden: false)
        if transaction.pocket.isHidden,
           result.contains(where: { $0.id == transaction.pocket.id }) == false {
            result.append(transaction.pocket)
        }
        return result.orderedPockets()
    }

    private var parsedAmount: Double? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var canSave: Bool {
        selectedPocket != nil
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (parsedAmount ?? 0) > 0
    }

    private func saveChanges() {
        guard let pocket = selectedPocket,
              let amount = parsedAmount,
              amount > 0
        else {
            showValidationAlert = true
            return
        }

        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        transaction.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.amount = amount
        transaction.transactionDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
        transaction.isIncome = selectedType.isIncome
        transaction.date = transactionDate
        transaction.pocket = pocket
        transaction.refreshPendingState()

        try? modelContext.save()
        Haptics.saveImpact()
        dismiss()
    }

    private func deleteTransaction() {
        modelContext.delete(transaction)
        try? modelContext.save()
        dismiss()
    }
}
