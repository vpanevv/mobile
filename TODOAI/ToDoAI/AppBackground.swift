import SwiftUI

struct AppBackground: View {
    @EnvironmentObject private var appearanceStore: AppearanceStore

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let isDark = appearanceStore.appearance.isDark

            ZStack {
                LinearGradient(
                    colors: isDark ? [
                        Color(red: 0.02, green: 0.04, blue: 0.10),
                        Color(red: 0.04, green: 0.08, blue: 0.16),
                        Color(red: 0.03, green: 0.18, blue: 0.24),
                    ] : [
                        Color(red: 0.98, green: 0.99, blue: 1.00),
                        Color(red: 0.92, green: 0.97, blue: 1.00),
                        Color(red: 0.86, green: 0.95, blue: 0.98),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                movingOrb(
                    color: isDark ? Color.cyan.opacity(0.20) : Color.cyan.opacity(0.16),
                    size: 340,
                    x: -120 + cos(time * 0.22) * 28,
                    y: -170 + sin(time * 0.18) * 24
                )

                movingOrb(
                    color: isDark ? Color.blue.opacity(0.18) : Color.blue.opacity(0.12),
                    size: 280,
                    x: 120 + sin(time * 0.14) * 36,
                    y: -10 + cos(time * 0.16) * 30
                )

                movingOrb(
                    color: isDark ? Color.white.opacity(0.10) : Color.white.opacity(0.58),
                    size: 260,
                    x: 130 + cos(time * 0.11) * 32,
                    y: 250 + sin(time * 0.13) * 36
                )

                ForEach(Array(sparkles(time: time).enumerated()), id: \.offset) { _, sparkle in
                    Image(systemName: sparkle.symbol)
                        .font(.system(size: sparkle.size, weight: .semibold))
                        .foregroundStyle(sparkle.color(isDark).opacity(sparkle.opacity))
                        .blur(radius: sparkle.blur)
                        .offset(x: sparkle.x, y: sparkle.y)
                }
            }
            .ignoresSafeArea()
        }
    }

    private func movingOrb(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 28)
            .offset(x: x, y: y)
    }

    private func sparkles(time: TimeInterval) -> [SparkleState] {
        [
            SparkleState(symbol: "sparkle", size: 18, x: -130 + sin(time * 0.45) * 18, y: -260 + cos(time * 0.28) * 26, opacity: 0.70, blur: 0.2, color: { $0 ? .white : Color.blue }),
            SparkleState(symbol: "sparkles", size: 14, x: 150 + cos(time * 0.33) * 24, y: -180 + sin(time * 0.29) * 20, opacity: 0.52, blur: 0.2, color: { _ in .cyan }),
            SparkleState(symbol: "circle.fill", size: 8, x: -170 + cos(time * 0.21) * 20, y: 90 + sin(time * 0.18) * 30, opacity: 0.34, blur: 0.8, color: { $0 ? .white : Color.black.opacity(0.35) }),
            SparkleState(symbol: "sparkle", size: 12, x: 140 + sin(time * 0.19) * 22, y: 150 + cos(time * 0.27) * 28, opacity: 0.40, blur: 0.4, color: { _ in .mint }),
            SparkleState(symbol: "sparkles", size: 16, x: 10 + sin(time * 0.24) * 44, y: 300 + cos(time * 0.17) * 22, opacity: 0.38, blur: 0.3, color: { $0 ? .white : Color.cyan.opacity(0.9) }),
            SparkleState(symbol: "circle.fill", size: 6, x: 110 + cos(time * 0.31) * 18, y: -40 + sin(time * 0.25) * 18, opacity: 0.26, blur: 0.8, color: { _ in .cyan }),
        ]
    }
}

private struct SparkleState {
    let symbol: String
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    let blur: CGFloat
    let color: (Bool) -> Color
}

struct GlassCard<Content: View>: View {
    @EnvironmentObject private var appearanceStore: AppearanceStore
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: appearanceStore.appearance.isDark ? [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.08),
                            ] : [
                                Color.white.opacity(0.95),
                                Color.black.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: appearanceStore.appearance.isDark ? Color.black.opacity(0.14) : Color.cyan.opacity(0.12),
                radius: 20,
                y: 8
            )
    }

    private var cardBackground: AnyShapeStyle {
        if appearanceStore.appearance.isDark {
            return AnyShapeStyle(.ultraThinMaterial)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.96),
                    Color(red: 0.92, green: 0.97, blue: 1.0),
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Label(priority.title, systemImage: priority.symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(priority.tint)
            .background(priority.tint.opacity(0.12), in: Capsule())
    }
}

struct LiveClockHeader: View {
    enum Style {
        case defaultDark
        case contrastOnLight
    }

    var style: Style = .defaultDark

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            VStack(spacing: 10) {
                Label {
                    Text(context.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: dateGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(calendarIconColor)
                }

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.headline.weight(.black))
                        .foregroundStyle(clockIconColor)

                    Text(context.date.formatted(.dateTime.hour().minute().second()))
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: clockGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: capsuleBackgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(capsuleStrokeColor, lineWidth: 1)
                }
                .shadow(color: capsuleShadowColor, radius: 18, y: 8)

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.cyan.opacity(0.95))
                        .frame(width: 8, height: 8)
                        .scaleEffect(0.86 + abs(sin(time * 1.8)) * 0.4)

                    Text("Live Focus Sync")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(syncLabelColor)
                        .textCase(.uppercase)
                        .tracking(1.1)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var dateGradientColors: [Color] {
        switch style {
        case .defaultDark:
            [Color.cyan.opacity(0.96), Color.white.opacity(0.92)]
        case .contrastOnLight:
            [Color.cyan.opacity(0.96), Color.blue.opacity(0.82)]
        }
    }

    private var calendarIconColor: Color {
        switch style {
        case .defaultDark:
            Color.cyan.opacity(0.88)
        case .contrastOnLight:
            Color.cyan.opacity(0.92)
        }
    }

    private var clockIconColor: Color {
        switch style {
        case .defaultDark:
            Color.white.opacity(0.92)
        case .contrastOnLight:
            Color.black.opacity(0.84)
        }
    }

    private var clockGradientColors: [Color] {
        switch style {
        case .defaultDark:
            [Color.white, Color.cyan, Color.mint.opacity(0.95)]
        case .contrastOnLight:
            [Color.black.opacity(0.92), Color.cyan.opacity(0.96), Color.blue.opacity(0.74)]
        }
    }

    private var capsuleBackgroundColors: [Color] {
        switch style {
        case .defaultDark:
            [Color.white.opacity(0.14), Color.cyan.opacity(0.08)]
        case .contrastOnLight:
            [Color.white.opacity(0.92), Color.cyan.opacity(0.12)]
        }
    }

    private var capsuleStrokeColor: Color {
        switch style {
        case .defaultDark:
            Color.white.opacity(0.18)
        case .contrastOnLight:
            Color.black.opacity(0.08)
        }
    }

    private var capsuleShadowColor: Color {
        switch style {
        case .defaultDark:
            Color.cyan.opacity(0.16)
        case .contrastOnLight:
            Color.cyan.opacity(0.12)
        }
    }

    private var syncLabelColor: Color {
        switch style {
        case .defaultDark:
            Color.white.opacity(0.78)
        case .contrastOnLight:
            Color.black.opacity(0.52)
        }
    }
}
