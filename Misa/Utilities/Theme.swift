import SwiftUI

extension Color {
    static var appThemeBackground: Color { Color("AppBackground") }
    static var appThemeCard: Color { Color("CardBackground") }

    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self = Color(red: red, green: green, blue: blue)
    }
}

struct PocketColorOption: Identifiable {
    let id = UUID()
    let name: String
    let hex: String

    var color: Color {
        Color(hex: hex)
    }
}

enum PocketColorPalette {
    static let `default` = "#0A84FF"

    static let options: [PocketColorOption] = [
        PocketColorOption(name: "Blue", hex: "#0A84FF"),
        PocketColorOption(name: "Royal Blue", hex: "#4169E1"),
        PocketColorOption(name: "Navy", hex: "#1D3557"),
        PocketColorOption(name: "Sky", hex: "#87CEEB"),
        PocketColorOption(name: "Cyan", hex: "#00BCD4"),
        PocketColorOption(name: "Green", hex: "#30D158"),
        PocketColorOption(name: "Lime", hex: "#A4C639"),
        PocketColorOption(name: "Forest", hex: "#228B22"),
        PocketColorOption(name: "Orange", hex: "#FF9F0A"),
        PocketColorOption(name: "Amber", hex: "#FFBF00"),
        PocketColorOption(name: "Coral", hex: "#FF7F50"),
        PocketColorOption(name: "Red", hex: "#FF3B30"),
        PocketColorOption(name: "Burgundy", hex: "#800020"),
        PocketColorOption(name: "Pink", hex: "#FF375F"),
        PocketColorOption(name: "Rose", hex: "#E91E63"),
        PocketColorOption(name: "Fuchsia", hex: "#FF00FF"),
        PocketColorOption(name: "Purple", hex: "#AF52DE"),
        PocketColorOption(name: "Teal", hex: "#64D2FF"),
        PocketColorOption(name: "Mint", hex: "#66D4CF"),
        PocketColorOption(name: "Indigo", hex: "#5E5CE6"),
        PocketColorOption(name: "Yellow", hex: "#FFD60A"),
        PocketColorOption(name: "Gold", hex: "#D4AF37"),
        PocketColorOption(name: "Brown", hex: "#8B5E3C"),
        PocketColorOption(name: "Slate", hex: "#708090"),
        PocketColorOption(name: "Gray", hex: "#8E8E93"),
        PocketColorOption(name: "Black", hex: "#1C1C1E")
    ]
}
