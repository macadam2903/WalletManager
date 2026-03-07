import Foundation

enum MoneyFormatter {
    static func string(from amount: Double, currency: CurrencyOption) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.locale = Locale.current
        if currency == .huf {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }

        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
}
