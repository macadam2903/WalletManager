import SwiftData
import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Query(sort: \Goal.name, order: .forward) private var goals: [Goal]
    @Query private var pockets: [Pocket]

    @State private var showAddGoalSheet = false
    @State private var selectedGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appThemeBackground
                    .ignoresSafeArea()

                if goals.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "target")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No goals yet")
                            .font(.headline)
                        Text("Set a savings target and track your progress.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .cardSurface(cornerRadius: 20)
                    .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(goals) { goal in
                                Button {
                                    selectedGoal = goal
                                } label: {
                                    goalCard(for: goal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showAddGoalSheet = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddGoalSheet) {
                AddGoalView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func goalCard(for goal: Goal) -> some View {
        let linkedPocket = linkedPocket(for: goal)
        let linkedBalance: Double? = {
            if goal.useAllPockets {
                return visiblePockets.reduce(0) { partialResult, pocket in
                    partialResult + (goal.includePendingTransactions ? pocket.projectedBalance : pocket.balance)
                }
            }

            return linkedPocket.map { pocket in
                goal.includePendingTransactions ? pocket.projectedBalance : pocket.balance
            }
        }()
        let current = goal.resolvedCurrentAmount(linkedPocketBalance: linkedBalance)
        let remaining = goal.remainingAmount(linkedPocketBalance: linkedBalance)
        let progress = goal.progress(linkedPocketBalance: linkedBalance)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.name)
                    .font(.headline)
                Spacer()
                if goal.useAllPockets {
                    Text("All")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2), in: Capsule())
                } else if let linkedPocket {
                    Text("\(linkedPocket.emoji ?? "💼")")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: linkedPocket.colorHex).opacity(0.2), in: Capsule())
                }
            }

            if goal.useAllPockets || linkedPocket != nil {
                Text(goal.includePendingTransactions ? "Includes scheduled transactions" : "Available balance only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.green)

            HStack {
                Text(MoneyFormatter.string(from: current, currency: settings.currency))
                    .font(.subheadline)
                Spacer()
                Text(MoneyFormatter.string(from: goal.targetAmount, currency: settings.currency))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("\(MoneyFormatter.string(from: remaining, currency: settings.currency)) remaining")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if let deadline = goal.deadline {
                Text("Deadline: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 18)
    }

    private func linkedPocket(for goal: Goal) -> Pocket? {
        if goal.useAllPockets {
            return nil
        }
        guard let linkedPocketID = goal.linkedPocketID else {
            return nil
        }
        return pockets.first(where: { $0.id == linkedPocketID })
    }

    private var visiblePockets: [Pocket] {
        pockets.orderedPockets(includeHidden: false)
    }
}
