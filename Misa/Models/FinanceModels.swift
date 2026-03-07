import Foundation
import SwiftData

@Model
final class Pocket {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var emoji: String?
    var createdAt: Date
    var sortOrder: Int
    var isHidden: Bool
    @Relationship(deleteRule: .cascade, inverse: \Transaction.pocket) var transactions: [Transaction]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        emoji: String? = nil,
        createdAt: Date = .now,
        sortOrder: Int? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.emoji = emoji
        self.createdAt = createdAt
        self.sortOrder = sortOrder ?? Int(createdAt.timeIntervalSince1970)
        self.isHidden = isHidden
        self.transactions = []
    }

    var balance: Double {
        transactions.reduce(into: 0) { partialResult, transaction in
            guard !transaction.effectiveIsPending else { return }
            partialResult += transaction.isIncome ? transaction.amount : -transaction.amount
        }
    }

    var projectedBalance: Double {
        transactions.reduce(into: 0) { partialResult, transaction in
            partialResult += transaction.isIncome ? transaction.amount : -transaction.amount
        }
    }

    var transactionCount: Int {
        transactions.count
    }
}

extension Collection where Element == Pocket {
    func orderedPockets(includeHidden: Bool = true) -> [Pocket] {
        let filteredPockets = includeHidden ? Array(self) : filter { !$0.isHidden }
        return filteredPockets.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var name: String
    var transactionDescription: String?
    var amount: Double
    var isIncome: Bool
    var date: Date
    var isPending: Bool
    var pocket: Pocket

    init(
        id: UUID = UUID(),
        name: String,
        transactionDescription: String? = nil,
        amount: Double,
        isIncome: Bool,
        date: Date,
        pocket: Pocket
    ) {
        self.id = id
        self.name = name
        self.transactionDescription = transactionDescription
        self.amount = amount
        self.isIncome = isIncome
        self.date = date
        self.isPending = date > .now
        self.pocket = pocket
    }

    var effectiveIsPending: Bool {
        date > .now
    }

    var signedAmount: Double {
        isIncome ? amount : -amount
    }

    func refreshPendingState(now: Date = .now) {
        isPending = date > now
    }
}

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var linkedPocketID: UUID?
    var useAllPockets: Bool
    var includePendingTransactions: Bool

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        deadline: Date? = nil,
        linkedPocketID: UUID? = nil,
        useAllPockets: Bool = false,
        includePendingTransactions: Bool = false
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.linkedPocketID = linkedPocketID
        self.useAllPockets = useAllPockets
        self.includePendingTransactions = includePendingTransactions
    }

    func resolvedCurrentAmount(linkedPocketBalance: Double?) -> Double {
        linkedPocketBalance ?? currentAmount
    }

    func progress(linkedPocketBalance: Double?) -> Double {
        guard targetAmount > 0 else { return 0 }
        let resolvedAmount = resolvedCurrentAmount(linkedPocketBalance: linkedPocketBalance)
        return min(max(resolvedAmount / targetAmount, 0), 1)
    }

    func remainingAmount(linkedPocketBalance: Double?) -> Double {
        let resolvedAmount = resolvedCurrentAmount(linkedPocketBalance: linkedPocketBalance)
        return max(targetAmount - resolvedAmount, 0)
    }
}
