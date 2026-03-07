import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let currency: CurrencyOption

    var body: some View {
        let isPending = transaction.effectiveIsPending
        let amountColor: Color = isPending ? .gray : (transaction.isIncome ? .green : .red)

        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(amountColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: isPending ? "clock" : (transaction.isIncome ? "plus" : "minus"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(amountColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.name)
                        .font(.headline)
                        .foregroundStyle(isPending ? .secondary : .primary)
                    Spacer()
                    Text(MoneyFormatter.string(from: transaction.signedAmount, currency: currency))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(amountColor)
                }

                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let description = transaction.transactionDescription,
                   !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(isPending ? .secondary : .primary)
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .cardSurface(cornerRadius: 16)
        .opacity(isPending ? 0.62 : 1)
    }
}
