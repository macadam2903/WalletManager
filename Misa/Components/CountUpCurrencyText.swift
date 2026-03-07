import SwiftUI

struct CountUpCurrencyText: View, Animatable {
    var amount: Double
    var currency: CurrencyOption

    var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }

    var body: some View {
        Text(MoneyFormatter.string(from: amount, currency: currency))
    }
}
