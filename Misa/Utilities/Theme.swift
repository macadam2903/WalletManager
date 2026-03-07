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
        PocketColorOption(name: "Green", hex: "#30D158"),
        PocketColorOption(name: "Orange", hex: "#FF9F0A"),
        PocketColorOption(name: "Pink", hex: "#FF375F"),
        PocketColorOption(name: "Teal", hex: "#64D2FF"),
        PocketColorOption(name: "Mint", hex: "#66D4CF"),
        PocketColorOption(name: "Indigo", hex: "#5E5CE6"),
        PocketColorOption(name: "Yellow", hex: "#FFD60A")
    ]
}
