import SwiftUI

extension Color {
    /// Creates a color from a `#RRGGBB` hex string.
    init?(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }
        guard string.count == 6, let value = Int(string, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension Car {
    /// A per-car accent derived from the car's photo, falling back to the
    /// brand accent when there's no photo / extracted color.
    var accentColor: Color {
        if let accentHex, let color = Color(hex: accentHex) {
            return color
        }
        return Theme.accent
    }
}
