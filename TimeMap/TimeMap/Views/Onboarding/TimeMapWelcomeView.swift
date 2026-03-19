import SwiftUI

struct TimeMapWelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        ZStack {
            TimeMapBackgroundView()

            VStack(spacing: 28) {
                Spacer(minLength: 12)

                AnimatedEarthHero()
                    .frame(height: 420)

                VStack(spacing: 18) {
                    Text("TimeMap")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Tap the world. Know the time.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TimeMapPalette.cloud)

                    Text("Explore cities, compare time zones instantly, and see every place in its own moment.")
                        .font(.body)
                        .foregroundStyle(TimeMapPalette.mutedCloud)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    welcomePanel

                    PrimaryActionButton(title: "Get Started", systemImage: "arrow.right") {
                        onGetStarted()
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.vertical, 20)
        }
    }

    private var welcomePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Featured experience", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)

            Text("A premium world clock for visually exploring time across the globe.")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                WelcomeFeatureChip(title: "Search cities", icon: "magnifyingglass")
                WelcomeFeatureChip(title: "Tap the map", icon: "globe")
                WelcomeFeatureChip(title: "Compare instantly", icon: "clock.arrow.2.circlepath")
            }
        }
        .padding(20)
        .timeMapGlass(cornerRadius: TimeMapMetrics.mediumCorner, tint: TimeMapGradient.aurora)
    }
}

private struct WelcomeFeatureChip: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.08), in: Capsule())
    }
}

private struct AnimatedEarthHero: View {
    private struct Node: Identifiable {
        let id = UUID()
        let city: String
        let timeZoneIdentifier: String
        let position: CGPoint
    }

    private let nodes: [Node] = [
        .init(city: "Tokyo", timeZoneIdentifier: "Asia/Tokyo", position: CGPoint(x: 0.84, y: 0.32)),
        .init(city: "London", timeZoneIdentifier: "Europe/London", position: CGPoint(x: 0.20, y: 0.35)),
        .init(city: "Dubai", timeZoneIdentifier: "Asia/Dubai", position: CGPoint(x: 0.78, y: 0.70)),
        .init(city: "New York", timeZoneIdentifier: "America/New_York", position: CGPoint(x: 0.18, y: 0.74))
    ]

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            ZStack {
                Circle()
                    .fill(TimeMapPalette.cyan.opacity(0.10))
                    .frame(width: 360, height: 360)
                    .blur(radius: 50)

                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: 348, height: 348)
                    .overlay(
                        Circle()
                            .trim(from: 0.20, to: 0.74)
                            .stroke(TimeMapGradient.sunrise, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(time * 9))
                    )

                EarthSphere(time: time)
                    .frame(width: 250, height: 250)

                ForEach(nodes) { node in
                    CityClockBadge(city: node.city, timeZoneIdentifier: node.timeZoneIdentifier)
                        .position(x: 52 + 250 * node.position.x, y: 72 + 250 * node.position.y)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct EarthSphere: View {
    let time: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            TimeMapPalette.cyan.opacity(0.70),
                            TimeMapPalette.electricBlue.opacity(0.75),
                            TimeMapPalette.deepOcean.opacity(0.98)
                        ],
                        center: .init(x: 0.38, y: 0.28),
                        startRadius: 8,
                        endRadius: 160
                    )
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.34)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Group {
                EarthContour(scaleY: 0.35, offsetY: -48)
                EarthContour(scaleY: 0.55, offsetY: -14)
                EarthContour(scaleY: 0.72, offsetY: 18)
            }

            ForEach(0..<4, id: \.self) { index in
                Ellipse()
                    .stroke(Color.white.opacity(index == 1 ? 0.16 : 0.08), lineWidth: 1)
                    .frame(width: 220, height: 220 - CGFloat(index * 34))
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? time * 7 : -time * 6))
            }

            EarthLandmassShape()
                .fill(TimeMapPalette.cyan.opacity(0.28))
                .frame(width: 210, height: 130)
                .rotationEffect(.degrees(time * 7))
                .offset(x: 6, y: -8)
                .blendMode(.screen)

            EarthLandmassShape()
                .fill(Color.white.opacity(0.10))
                .frame(width: 176, height: 108)
                .rotationEffect(.degrees(-time * 5))
                .offset(x: -14, y: 26)
                .blendMode(.screen)

            Circle()
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.30), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .blur(radius: 10)
                .scaleEffect(x: 0.78, y: 0.52)
                .offset(x: -30, y: -40)
        }
        .shadow(color: TimeMapPalette.electricBlue.opacity(0.26), radius: 28, y: 16)
    }
}

private struct EarthContour: View {
    let scaleY: CGFloat
    let offsetY: CGFloat

    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.09), lineWidth: 1)
            .scaleEffect(x: 1, y: scaleY)
            .offset(y: offsetY)
    }
}

private struct EarthLandmassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.20),
                      control1: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.18),
                      control2: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.10))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY + rect.height * 0.30),
                      control1: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.24),
                      control2: CGPoint(x: rect.minX + rect.width * 0.50, y: rect.minY + rect.height * 0.18))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.74, y: rect.midY),
                      control1: CGPoint(x: rect.minX + rect.width * 0.67, y: rect.minY + rect.height * 0.45),
                      control2: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.40))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.60, y: rect.maxY - rect.height * 0.18),
                      control1: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.maxY - rect.height * 0.10),
                      control2: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.maxY - rect.height * 0.06))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY - rect.height * 0.20),
                      control1: CGPoint(x: rect.minX + rect.width * 0.53, y: rect.maxY - rect.height * 0.26),
                      control2: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.08))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.midY),
                      control1: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.maxY - rect.height * 0.38),
                      control2: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY - rect.height * 0.18))
        path.closeSubpath()
        return path
    }
}

private struct CityClockBadge: View {
    let city: String
    let timeZoneIdentifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(city)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            Text(clockText)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(TimeMapPalette.cloud)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            Circle()
                .fill(TimeMapGradient.sunrise)
                .frame(width: 7, height: 7)
                .blur(radius: 0.4)
                .offset(x: -3)
        }
        .timeMapGlass(cornerRadius: 16, tint: TimeMapGradient.aurora)
    }

    private var clockText: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier)
        return formatter.string(from: Date())
    }
}
