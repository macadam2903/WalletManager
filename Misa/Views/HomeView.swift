import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Query private var pockets: [Pocket]

    @State private var selectedPocketID: UUID?
    @State private var addTransactionType: AddTransactionView.TransactionType? = nil
    @State private var selectedTransaction: Transaction?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.appThemeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        totalBalanceCard

                        pocketCarousel

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Transactions")
                                .font(.headline)

                            if selectedTransactions.isEmpty {
                                emptyTransactionsState
                            } else {
                                ForEach(selectedTransactions) { transaction in
                                    Button {
                                        selectedTransaction = transaction
                                    } label: {
                                        TransactionRowView(transaction: transaction, currency: settings.currency)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 92)
                    }
                    .padding(.top, 12)
                }

                addTransactionButtons
                    .padding(.bottom, 20)
            }
            .navigationTitle("")
            .sheet(item: $addTransactionType) { type in
                AddTransactionView(
                    preselectedPocketID: selectedPocket?.id,
                    initialType: type,
                    autoFocusNameOnAppear: true
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedTransaction) { transaction in
                EditTransactionView(transaction: transaction)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                syncSelection()
            }
            .onChange(of: visiblePockets.count) {
                syncSelection()
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedPocketID)
        }
    }

    private var totalBalanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Currently available balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            CountUpCurrencyText(amount: availableTotalBalance, currency: settings.currency)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack {
                Text("Total balance with scheduled transfers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                CountUpCurrencyText(amount: projectedTotalBalance, currency: settings.currency)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.top, 2)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 24)
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: availableTotalBalance)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: projectedTotalBalance)
    }

    @ViewBuilder
    private var pocketCarousel: some View {
        if visiblePockets.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No pockets yet")
                    .font(.headline)
                Text("Create your first pocket in the Pockets tab to start tracking money.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: 20)
            .padding(.horizontal, 20)
        } else {
            TabView(selection: $selectedPocketID) {
                ForEach(visiblePockets) { pocket in
                    PocketCardView(pocket: pocket, currency: settings.currency)
                        .padding(.horizontal, 20)
                        .tag(Optional(pocket.id))
                }
            }
            .frame(height: 180)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }

    private var emptyTransactionsState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No transactions for this pocket yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 16)
    }

    private var addTransactionButtons: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.buttonTap()
                addTransactionType = .expense
            } label: {
                addButtonLabel(title: "New Expense", color: .red, icon: "minus.circle.fill")
            }
            .accessibilityIdentifier("newExpenseFAB")
            Button {
                Haptics.buttonTap()
                addTransactionType = .income
            } label: {
                addButtonLabel(title: "New Income", color: .green, icon: "plus.circle.fill")
            }
            .accessibilityIdentifier("newIncomeFAB")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func addButtonLabel(title: String, color: Color, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.vertical, 14)
            .frame(width: 180)
            .background(
                Capsule(style: .continuous)
                    .fill(color)
            )
            .foregroundStyle(.white)
            .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 6)
    }

    private var selectedPocket: Pocket? {
        guard let selectedPocketID else { return visiblePockets.first }
        return visiblePockets.first(where: { $0.id == selectedPocketID }) ?? visiblePockets.first
    }

    private var selectedTransactions: [Transaction] {
        let transactions = selectedPocket?.transactions ?? []
        return transactions.sorted(by: { $0.date > $1.date })
    }

    private var availableTotalBalance: Double {
        visiblePockets.reduce(0) { partialResult, pocket in
            partialResult + pocket.balance
        }
    }

    private var projectedTotalBalance: Double {
        visiblePockets.reduce(0) { partialResult, pocket in
            partialResult + pocket.projectedBalance
        }
    }

    private func syncSelection() {
        guard !visiblePockets.isEmpty else {
            selectedPocketID = nil
            return
        }

        if let selectedPocketID,
           visiblePockets.contains(where: { $0.id == selectedPocketID }) {
            return
        }

        selectedPocketID = visiblePockets.first?.id
    }

    private var visiblePockets: [Pocket] {
        pockets.orderedPockets(includeHidden: false)
    }
}

#Preview {
    HomeView()
        .environmentObject(SettingsStore())
        .modelContainer(for: [Pocket.self, Transaction.self, Goal.self], inMemory: true)
}
