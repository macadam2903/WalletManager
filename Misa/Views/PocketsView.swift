import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct PocketsView: View {
    private enum EditorSheet: Identifiable {
        case create
        case edit(Pocket)

        var id: String {
            switch self {
            case .create:
                return "create"
            case let .edit(pocket):
                return "edit-\(pocket.id.uuidString)"
            }
        }

        var pocket: Pocket? {
            switch self {
            case .create:
                return nil
            case let .edit(pocket):
                return pocket
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore
    @Query private var pockets: [Pocket]

    @State private var activeSheet: EditorSheet?
    @State private var pocketPendingDeletion: Pocket?
    @State private var draggedPocket: Pocket?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appThemeBackground
                    .ignoresSafeArea()

                if visiblePockets.isEmpty && hiddenPockets.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "wallet.pass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No pockets yet")
                            .font(.headline)
                        Text("Add your first pocket to start tracking balances.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .cardSurface(cornerRadius: 20)
                    .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if !visiblePockets.isEmpty {
                                ForEach(visiblePockets) { pocket in
                                    pocketRow(for: pocket, isHiddenSection: false)
                                        .onDrag {
                                            draggedPocket = pocket
                                            return NSItemProvider(object: pocket.id.uuidString as NSString)
                                        }
                                        .onDrop(
                                            of: [UTType.text],
                                            delegate: PocketDropDelegate(
                                                destinationPocket: pocket,
                                                visiblePockets: visiblePockets,
                                                draggedPocket: $draggedPocket,
                                                moveAction: moveVisiblePocket
                                            )
                                        )
                                }
                            }

                            if !hiddenPockets.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Hidden pockets")
                                        .font(.headline)
                                        .padding(.horizontal, 4)

                                    ForEach(hiddenPockets) { pocket in
                                        pocketRow(for: pocket, isHiddenSection: true)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Pockets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            activeSheet = .create
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                PocketEditorView(pocket: sheet.pocket)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .alert("Delete pocket?", isPresented: deletionAlertBinding) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) {
                    pocketPendingDeletion = nil
                }
            } message: {
                if let pocket = pocketPendingDeletion {
                    if pocket.transactions.isEmpty {
                        Text("This action cannot be undone.")
                    } else {
                        Text("This pocket contains \(pocket.transactions.count) transactions. Deleting it will remove them too.")
                    }
                }
            }
            .onAppear {
                normalizeSortOrderIfNeeded()
            }
        }
    }

    private func pocketRow(for pocket: Pocket, isHiddenSection: Bool) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(hex: pocket.colorHex))
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(pocket.emoji ?? "💼") \(pocket.name)")
                    .font(.headline)
                Text("\(pocket.transactionCount) transactions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(MoneyFormatter.string(from: pocket.balance, currency: settings.currency))
                    .font(.headline)
                HStack(spacing: 10) {
                    if isHiddenSection {
                        Button {
                            unhidePocket(pocket)
                        } label: {
                            Image(systemName: "eye")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)

                        Button {
                            hidePocket(pocket)
                        } label: {
                            Image(systemName: "eye.slash")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        activeSheet = .edit(pocket)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        pocketPendingDeletion = pocket
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 16)
    }

    private var deletionAlertBinding: Binding<Bool> {
        Binding(
            get: { pocketPendingDeletion != nil },
            set: { newValue in
                if !newValue {
                    pocketPendingDeletion = nil
                }
            }
        )
    }

    private func confirmDelete() {
        guard let pocket = pocketPendingDeletion else { return }
        modelContext.delete(pocket)
        try? modelContext.save()
        pocketPendingDeletion = nil
    }

    private var visiblePockets: [Pocket] {
        pockets.orderedPockets(includeHidden: false)
    }

    private var hiddenPockets: [Pocket] {
        pockets.filter(\.isHidden).orderedPockets()
    }

    private func moveVisiblePocket(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        var reordered = visiblePockets
        reordered.move(
            fromOffsets: IndexSet(integer: sourceIndex),
            toOffset: destinationIndex
        )

        for (index, pocket) in reordered.enumerated() {
            pocket.sortOrder = index
        }

        try? modelContext.save()
    }

    private func hidePocket(_ pocket: Pocket) {
        pocket.isHidden = true
        try? modelContext.save()
    }

    private func unhidePocket(_ pocket: Pocket) {
        pocket.isHidden = false
        try? modelContext.save()
    }

    private func normalizeSortOrderIfNeeded() {
        let ordered = pockets.orderedPockets()
        let needsNormalize = ordered.enumerated().contains { index, pocket in
            pocket.sortOrder != index
        }

        guard needsNormalize else { return }

        for (index, pocket) in ordered.enumerated() {
            pocket.sortOrder = index
        }

        try? modelContext.save()
    }
}

private struct PocketDropDelegate: DropDelegate {
    let destinationPocket: Pocket
    let visiblePockets: [Pocket]
    @Binding var draggedPocket: Pocket?
    let moveAction: (_ sourceIndex: Int, _ destinationIndex: Int) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard let draggedPocket,
              draggedPocket.id != destinationPocket.id,
              let sourceIndex = visiblePockets.firstIndex(where: { $0.id == draggedPocket.id }),
              let destinationIndex = visiblePockets.firstIndex(where: { $0.id == destinationPocket.id })
        else {
            return
        }

        let adjustedDestination = destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex
        moveAction(sourceIndex, adjustedDestination)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedPocket = nil
        return true
    }
}
