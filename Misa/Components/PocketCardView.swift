import SwiftUI

struct PocketCardView: View {
    let pocket: Pocket
    let currency: CurrencyOption

    var body: some View {
        let accent = Color(hex: pocket.colorHex)

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(pocket.emoji ?? "💼")
                    .font(.title3)
                Text(pocket.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
            }

            CountUpCurrencyText(amount: pocket.balance, currency: currency)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                Image(systemName: "wallet.pass")
                    .font(.caption)
                Text("\(pocket.transactionCount) transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appThemeCard.opacity(0.9))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.28), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(accent.opacity(0.35), lineWidth: 1)
                )
        }
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
    }
}
