import SwiftUI

struct AppBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.04, blue: 0.10),
                        Color(red: 0.04, green: 0.08, blue: 0.16),
                        Color(red: 0.03, green: 0.18, blue: 0.24),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                movingOrb(
                    color: Color.cyan.opacity(0.20),
                    size: 340,
                    x: -120 + cos(time * 0.22) * 28,
                    y: -170 + sin(time * 0.18) * 24
                )

                movingOrb(
                    color: Color.blue.opacity(0.18),
                    size: 280,
                    x: 120 + sin(time * 0.14) * 36,
                    y: -10 + cos(time * 0.16) * 30
                )

                movingOrb(
                    color: Color.white.opacity(0.10),
                    size: 260,
                    x: 130 + cos(time * 0.11) * 32,
                    y: 250 + sin(time * 0.13) * 36
                )

                ForEach(Array(sparkles(time: time).enumerated()), id: \.offset) { _, sparkle in
                    Image(systemName: sparkle.symbol)
                        .font(.system(size: sparkle.size, weight: .semibold))
                        .foregroundStyle(sparkle.color.opacity(sparkle.opacity))
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
            SparkleState(symbol: "sparkle", size: 18, x: -130 + sin(time * 0.45) * 18, y: -260 + cos(time * 0.28) * 26, opacity: 0.70, blur: 0.2, color: .white),
            SparkleState(symbol: "sparkles", size: 14, x: 150 + cos(time * 0.33) * 24, y: -180 + sin(time * 0.29) * 20, opacity: 0.52, blur: 0.2, color: .cyan),
            SparkleState(symbol: "circle.fill", size: 8, x: -170 + cos(time * 0.21) * 20, y: 90 + sin(time * 0.18) * 30, opacity: 0.34, blur: 0.8, color: .white),
            SparkleState(symbol: "sparkle", size: 12, x: 140 + sin(time * 0.19) * 22, y: 150 + cos(time * 0.27) * 28, opacity: 0.40, blur: 0.4, color: .mint),
            SparkleState(symbol: "sparkles", size: 16, x: 10 + sin(time * 0.24) * 44, y: 300 + cos(time * 0.17) * 22, opacity: 0.38, blur: 0.3, color: .white),
            SparkleState(symbol: "circle.fill", size: 6, x: 110 + cos(time * 0.31) * 18, y: -40 + sin(time * 0.25) * 18, opacity: 0.26, blur: 0.8, color: .cyan),
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
    let color: Color
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.14), radius: 20, y: 8)
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
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 8) {
                Text(context.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.white.opacity(0.82))

                    Text(context.date.formatted(.dateTime.hour().minute().second()))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
