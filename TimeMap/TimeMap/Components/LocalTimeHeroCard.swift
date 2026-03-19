import SwiftUI

struct LocalTimeHeroCard: View {
    let info: LocalTimeInfo

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR LOCAL TIME")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(Color.white.opacity(0.76))

                        Text(info.currentTimeText)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    HeroStatusBadge()
                }

                Text(info.placeLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 10) {
                    HeroInfoChip(icon: "calendar", text: info.dateText)
                    HeroInfoChip(icon: "globe.americas.fill", text: info.timeZoneName)
                }

                Text(info.timeZoneIdentifier)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)

            EarthMiniOrb()
                .frame(width: 88, height: 88)
                .padding(16)
        }
        .timeMapHeroSurface()
    }
}

private struct HeroStatusBadge: View {
    var body: some View {
        Label("Live", systemImage: "dot.radiowaves.left.and.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12), in: Capsule())
    }
}

private struct HeroInfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.10), in: Capsule())
            .lineLimit(1)
    }
}

private struct EarthMiniOrb: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [TimeMapPalette.cyan.opacity(0.82), TimeMapPalette.electricBlue, TimeMapPalette.deepOcean],
                        center: .init(x: 0.35, y: 0.28),
                        startRadius: 4,
                        endRadius: 80
                    )
                )
            Circle()
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                .scaleEffect(x: 1, y: 0.58)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.26), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .scaleEffect(x: 0.8, y: 0.5)
                .offset(x: -12, y: -12)
        }
        .shadow(color: TimeMapPalette.electricBlue.opacity(0.32), radius: 18, y: 10)
    }
}
