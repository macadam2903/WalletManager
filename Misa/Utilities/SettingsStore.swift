import Combine
import Foundation
import SwiftUI

enum AppearanceMode: String {
    case dark
    case light

    var preferredColorScheme: ColorScheme {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

enum CurrencyOption: String, CaseIterable, Identifiable {
    case huf = "HUF"
    case eur = "EUR"
    case usd = "USD"

    var id: String { rawValue }
}

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let appearanceMode = "appearanceMode"
        static let currency = "currency"
    }

    @Published var appearanceMode: AppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        }
    }

    @Published var currency: CurrencyOption {
        didSet {
            defaults.set(currency.rawValue, forKey: Keys.currency)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "") ?? .dark
        currency = CurrencyOption(rawValue: defaults.string(forKey: Keys.currency) ?? "") ?? .huf
    }

    var preferredColorScheme: ColorScheme {
        appearanceMode.preferredColorScheme
    }
}
