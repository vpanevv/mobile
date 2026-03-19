import SwiftUI

enum TimeMapPalette {
    static let midnight = Color(red: 0.08, green: 0.10, blue: 0.22)
    static let twilight = Color(red: 0.17, green: 0.20, blue: 0.44)
    static let aurora = Color(red: 0.16, green: 0.74, blue: 0.93)
    static let sunrise = Color(red: 1.00, green: 0.63, blue: 0.42)
    static let violet = Color(red: 0.46, green: 0.39, blue: 0.95)
    static let mist = Color.white.opacity(0.72)
    static let cardFill = Color.white.opacity(0.10)
    static let darkCardFill = Color.black.opacity(0.22)
    static let border = Color.white.opacity(0.16)
    static let shadow = Color.black.opacity(0.22)
}

enum TimeMapGradient {
    static let hero = LinearGradient(
        colors: [TimeMapPalette.violet, TimeMapPalette.twilight, TimeMapPalette.aurora],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = LinearGradient(
        colors: [TimeMapPalette.sunrise, TimeMapPalette.violet],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let chip = LinearGradient(
        colors: [TimeMapPalette.aurora.opacity(0.9), TimeMapPalette.violet.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct TimeMapBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TimeMapPalette.midnight,
                    TimeMapPalette.twilight,
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(TimeMapPalette.aurora.opacity(0.28))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 140, y: -230)

            Circle()
                .fill(TimeMapPalette.sunrise.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -150, y: -120)

            Circle()
                .fill(TimeMapPalette.violet.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 110)
                .offset(x: -140, y: 320)

            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.12))
        }
        .ignoresSafeArea()
    }
}

struct TimeMapCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground).opacity(0.28))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(TimeMapPalette.border, lineWidth: 1)
                    )
                    .shadow(color: TimeMapPalette.shadow, radius: 24, y: 16)
            )
    }
}

struct TimeMapHeroCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(TimeMapGradient.hero)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: TimeMapPalette.violet.opacity(0.30), radius: 28, y: 16)
            )
    }
}

extension View {
    func timeMapCard() -> some View {
        modifier(TimeMapCardModifier())
    }

    func timeMapHeroCard() -> some View {
        modifier(TimeMapHeroCardModifier())
    }
}
