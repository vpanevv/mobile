import SwiftUI

struct LocalTimeHeroCard: View {
    let info: LocalTimeInfo
    let favoritesCount: Int
    let openFavorites: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Local Time", systemImage: "location.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.82))

                Text(info.currentTimeText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                VStack(alignment: .leading, spacing: 6) {
                    Text(info.placeLabel)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(info.timeZoneName)
                        .font(.subheadline)
                        .foregroundStyle(TimeMapPalette.cloud)

                    Text(info.timeZoneIdentifier)
                        .font(.caption)
                        .foregroundStyle(TimeMapPalette.mutedCloud)
                }

                Button(action: openFavorites) {
                    HStack(spacing: 10) {
                        Image(systemName: favoritesCount == 0 ? "heart" : "heart.fill")
                            .font(.system(size: 14, weight: .semibold))

                        Text(favoritesCount == 0 ? "Favorites" : "Favorites \(favoritesCount)")
                            .font(.subheadline.weight(.semibold))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.14))
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 8)

            StylizedEarthView()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(TimeMapGradient.localHero)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.clear, Color.black.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: TimeMapPalette.violet.opacity(0.28), radius: 28, y: 16)
        )
    }
}

private struct StylizedEarthView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(TimeMapPalette.cyan.opacity(0.14))
                .frame(width: 108, height: 108)
                .blur(radius: 20)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            TimeMapPalette.cyan.opacity(0.95),
                            TimeMapPalette.electricBlue.opacity(0.92),
                            TimeMapPalette.deepOcean.opacity(0.98)
                        ],
                        center: .init(x: 0.34, y: 0.28),
                        startRadius: 6,
                        endRadius: 90
                    )
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            EarthLandmassBlob()
                .fill(Color.white.opacity(0.18))
                .frame(width: 70, height: 44)
                .offset(x: -10, y: -12)
                .blur(radius: 0.3)

            EarthLandmassBlob()
                .fill(TimeMapPalette.cyan.opacity(0.22))
                .frame(width: 62, height: 38)
                .rotationEffect(.degrees(18))
                .offset(x: 12, y: 12)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .scaleEffect(x: 1, y: 0.56)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .scaleEffect(x: 0.72, y: 1)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .scaleEffect(x: 0.72, y: 0.48)
                .offset(x: -14, y: -15)

            Circle()
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        }
        .frame(width: 82, height: 82)
        .shadow(color: TimeMapPalette.electricBlue.opacity(0.30), radius: 18, y: 10)
    }
}

private struct EarthLandmassBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.12),
                      control1: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.14),
                      control2: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.04))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.32),
                      control1: CGPoint(x: rect.minX + rect.width * 0.50, y: rect.minY + rect.height * 0.24),
                      control2: CGPoint(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.18))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.midY),
                      control1: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.44),
                      control2: CGPoint(x: rect.minX + rect.width * 0.90, y: rect.minY + rect.height * 0.40))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY - rect.height * 0.10),
                      control1: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.maxY - rect.height * 0.08),
                      control2: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.maxY - rect.height * 0.04))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.maxY - rect.height * 0.18),
                      control1: CGPoint(x: rect.minX + rect.width * 0.54, y: rect.maxY - rect.height * 0.18),
                      control2: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.02))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY),
                      control1: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY - rect.height * 0.30),
                      control2: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.maxY - rect.height * 0.10))
        path.closeSubpath()
        return path
    }
}
