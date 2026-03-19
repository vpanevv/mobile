import SwiftUI

enum TimeMapPalette {
    static let night = Color(red: 0.03, green: 0.06, blue: 0.15)
    static let deepOcean = Color(red: 0.07, green: 0.16, blue: 0.34)
    static let indigo = Color(red: 0.24, green: 0.25, blue: 0.63)
    static let electricBlue = Color(red: 0.14, green: 0.62, blue: 0.97)
    static let cyan = Color(red: 0.28, green: 0.88, blue: 0.96)
    static let violet = Color(red: 0.49, green: 0.36, blue: 0.94)
    static let sunrise = Color(red: 1.00, green: 0.67, blue: 0.43)
    static let cloud = Color.white.opacity(0.86)
    static let mutedCloud = Color.white.opacity(0.62)
    static let hairline = Color.white.opacity(0.14)
    static let shadow = Color.black.opacity(0.30)
}

enum TimeMapGradient {
    static let atmosphere = LinearGradient(
        colors: [TimeMapPalette.night, TimeMapPalette.deepOcean, TimeMapPalette.indigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let aurora = LinearGradient(
        colors: [TimeMapPalette.violet, TimeMapPalette.electricBlue, TimeMapPalette.cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sunrise = LinearGradient(
        colors: [TimeMapPalette.sunrise, TimeMapPalette.violet],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let hero = LinearGradient(
        colors: [
            TimeMapPalette.violet.opacity(0.98),
            TimeMapPalette.indigo.opacity(0.96),
            TimeMapPalette.electricBlue.opacity(0.92)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let localHero = LinearGradient(
        colors: [
            TimeMapPalette.deepOcean.opacity(0.98),
            TimeMapPalette.indigo.opacity(0.96),
            TimeMapPalette.violet.opacity(0.92)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum TimeMapMetrics {
    static let largeCorner: CGFloat = 32
    static let mediumCorner: CGFloat = 26
    static let smallCorner: CGFloat = 20
}

struct TimeMapBackgroundView: View {
    var body: some View {
        ZStack {
            TimeMapGradient.atmosphere

            StarfieldLayer()
                .opacity(0.55)

            Circle()
                .fill(TimeMapPalette.cyan.opacity(0.22))
                .frame(width: 380, height: 380)
                .blur(radius: 100)
                .offset(x: 150, y: -250)

            Circle()
                .fill(TimeMapPalette.violet.opacity(0.24))
                .frame(width: 420, height: 420)
                .blur(radius: 120)
                .offset(x: -180, y: -70)

            Circle()
                .fill(TimeMapPalette.sunrise.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 160, y: 280)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .ignoresSafeArea()
    }
}

private struct StarfieldLayer: View {
    private let stars: [CGPoint] = [
        .init(x: 0.08, y: 0.11), .init(x: 0.18, y: 0.22), .init(x: 0.78, y: 0.14),
        .init(x: 0.88, y: 0.19), .init(x: 0.68, y: 0.28), .init(x: 0.29, y: 0.33),
        .init(x: 0.14, y: 0.44), .init(x: 0.86, y: 0.42), .init(x: 0.57, y: 0.51),
        .init(x: 0.38, y: 0.62), .init(x: 0.78, y: 0.64), .init(x: 0.16, y: 0.75),
        .init(x: 0.67, y: 0.80), .init(x: 0.44, y: 0.88), .init(x: 0.91, y: 0.86)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(stars.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(Color.white.opacity(index.isMultiple(of: 3) ? 0.85 : 0.45))
                        .frame(width: index.isMultiple(of: 4) ? 3 : 2, height: index.isMultiple(of: 4) ? 3 : 2)
                        .blur(radius: index.isMultiple(of: 5) ? 1.4 : 0)
                        .position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
                }
            }
        }
    }
}

struct TimeMapGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var tint: LinearGradient?

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.16))
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(TimeMapPalette.hairline, lineWidth: 1)
                    )
                    .shadow(color: TimeMapPalette.shadow, radius: 28, y: 18)
            )
    }
}

struct TimeMapHeroSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: TimeMapMetrics.largeCorner, style: .continuous)
                    .fill(TimeMapGradient.hero)
                    .overlay(
                        RoundedRectangle(cornerRadius: TimeMapMetrics.largeCorner, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), Color.clear, Color.black.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TimeMapMetrics.largeCorner, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: TimeMapPalette.violet.opacity(0.36), radius: 34, y: 18)
            )
    }
}

struct TimeMapPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(TimeMapGradient.sunrise)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: TimeMapPalette.sunrise.opacity(0.28), radius: 16, y: 10)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

extension View {
    func timeMapGlass(cornerRadius: CGFloat = TimeMapMetrics.mediumCorner, tint: LinearGradient? = nil) -> some View {
        modifier(TimeMapGlassModifier(cornerRadius: cornerRadius, tint: tint))
    }

    func timeMapHeroSurface() -> some View {
        modifier(TimeMapHeroSurfaceModifier())
    }
}
