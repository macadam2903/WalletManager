import SwiftData
import SwiftUI

struct AddTransactionView: View {
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

    let preselectedPocketID: UUID?
    let initialType: TransactionType
    let autoFocusNameOnAppear: Bool

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
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appThemeBackground
                    .ignoresSafeArea()

                if visiblePockets.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "wallet.pass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No pockets available")
                            .font(.headline)
                        Text("Create a pocket first in the Pockets tab.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .cardSurface(cornerRadius: 18)
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            sectionCard(title: "Pocket") {
                                if visiblePockets.count <= 3 {
                                    Picker("Pocket", selection: pocketSelection) {
                                        ForEach(visiblePockets) { pocket in
                                            Text("\(pocket.emoji ?? "💼") \(pocket.name)").tag(pocket.id)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                } else {
                                    Picker("Pocket", selection: pocketSelection) {
                                        ForEach(visiblePockets) { pocket in
                                            Text("\(pocket.emoji ?? "💼") \(pocket.name)")
                                                .tag(pocket.id)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }

                            sectionCard(title: "Details") {
                                VStack(spacing: 12) {
                                    TextField("Name (e.g. Groceries)", text: $name)
                                        .textInputAutocapitalization(.words)
                                        .focused($isNameFieldFocused)
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
                                        .overlay(alignment: .topLeading) {
                                            if descriptionText.isEmpty {
                                                Text("Description (optional)")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 14)
                                                    .allowsHitTesting(false)
                                            }
                                        }
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

                                    if transactionDate > Date.now {
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock")
                                                .foregroundStyle(.secondary)
                                            Text("This transaction will be marked as pending until its date.")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }

                            Button {
                                saveTransaction()
                            } label: {
                                Text("Save")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 4)
                            .disabled(!canSave)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(selectedType == .income ? "New Income" : "New Expense")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid transaction", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please provide a name, amount and pocket.")
            }
            .task(id: initialType) {
                selectedType = initialType
                if let preselectedPocketID,
                   visiblePockets.contains(where: { $0.id == preselectedPocketID }) {
                    selectedPocketID = preselectedPocketID
                } else {
                    selectedPocketID = visiblePockets.first?.id
                }

                if autoFocusNameOnAppear {
                    DispatchQueue.main.async {
                        isNameFieldFocused = true
                    }
                }
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
            selectedPocketID ?? visiblePockets.first?.id ?? UUID()
        } set: { newValue in
            selectedPocketID = newValue
        }
    }

    private var selectedPocket: Pocket? {
        guard let selectedPocketID else { return nil }
        return visiblePockets.first(where: { $0.id == selectedPocketID })
    }

    private var visiblePockets: [Pocket] {
        pockets.orderedPockets(includeHidden: false)
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

    private func saveTransaction() {
        guard let pocket = selectedPocket,
              let amount = parsedAmount,
              amount > 0
        else {
            showValidationAlert = true
            return
        }

        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        let transaction = Transaction(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            transactionDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
            amount: amount,
            isIncome: selectedType.isIncome,
            date: transactionDate,
            pocket: pocket
        )
        transaction.refreshPendingState()

        modelContext.insert(transaction)
        try? modelContext.save()

        Haptics.saveImpact()
        dismiss()
    }
}
