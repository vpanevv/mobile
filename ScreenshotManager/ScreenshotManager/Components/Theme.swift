import SwiftUI

extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    /// Warm off-white canvas behind everything.
    static let canvas = Color(light: UIColor(red: 0.957, green: 0.953, blue: 0.937, alpha: 1),
                              dark: UIColor(red: 0.055, green: 0.055, blue: 0.063, alpha: 1))
    /// Raised card surface.
    static let card = Color(light: .white,
                            dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1))
    static let thumbFill = Color(light: UIColor(white: 0.9, alpha: 1),
                                   dark: UIColor(white: 0.18, alpha: 1))
}

struct CanvasBackground: View {
    var body: some View {
        Color.canvas
            .overlay(alignment: .top) {
                LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 320)
                    .blendMode(.softLight)
            }
            .ignoresSafeArea()
    }
}

struct CardSurface: ViewModifier {
    var radius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .background(Color.card, in: .rect(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
            .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}

extension View {
    func cardSurface(radius: CGFloat = 26) -> some View { modifier(CardSurface(radius: radius)) }
}

/// Round Liquid Glass icon button used in headers and viewers.
struct GlassCircleButton: View {
    let systemImage: String
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .frame(width: size, height: size)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}

extension Date {
    var relativeLabel: String {
        if Calendar.current.isDateInToday(self) {
            return "Today, " + formatted(date: .omitted, time: .shortened)
        }
        if Calendar.current.isDateInYesterday(self) {
            return "Yesterday, " + formatted(date: .omitted, time: .shortened)
        }
        return formatted(date: .abbreviated, time: .shortened)
    }
}
