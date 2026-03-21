import SwiftUI

struct SelectedCityPopupCard: View {
    let snapshot: LocationTimeSnapshot
    let dismiss: () -> Void

    @State private var animateMood = false

    private var mood: TimeMoodTheme {
        TimeMoodTheme(snapshot: snapshot)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            heroMoodMoment
            metricsRow
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: 420, minHeight: 340, maxHeight: 430, alignment: .topLeading)
        .background(cardBackground)
        .overlay(cardStroke)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: mood.shadowColor, radius: 40, y: 24)
        .onAppear {
            animateMood = true
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 58, height: 58)

                        Text(FlagUtility.emoji(for: snapshot.location.countryCode))
                            .font(.system(size: 32))
                    }
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(snapshot.location.city)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(snapshot.location.country)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                }

                Spacer(minLength: 12)

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12), in: Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Text(snapshot.dateText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var heroMoodMoment: some View {
        VStack(spacing: 16) {
            moodSymbol

            Text(snapshot.currentTimeText)
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .contentTransition(.numericText())
                .multilineTextAlignment(.center)

            VStack(spacing: 7) {
                HStack(spacing: 10) {
                    Image(systemName: mood.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(mood.iconColor)

                    Text(mood.title)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.14))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        )
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    private var moodSymbol: some View {
        ZStack {
            Circle()
                .fill(mood.symbolBackground)
                .frame(width: 108, height: 108)
                .blur(radius: 2)
                .scaleEffect(animateMood ? 1.02 : 0.98)
                .opacity(animateMood ? 1 : 0.92)

            Circle()
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                .frame(width: 118, height: 118)

            Image(systemName: mood.heroIconName)
                .font(.system(size: mood.kind == .night ? 38 : 34, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(mood.iconColor)
                .offset(y: animateMood ? -2 : 2)
                .shadow(color: mood.iconColor.opacity(0.28), radius: 12)
        }
        .frame(height: 122)
        .animation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true), value: animateMood)
    }

    private var metricsRow: some View {
        HStack(spacing: 10) {
            PopupInfoChip(
                icon: "globe.americas.fill",
                title: "Timezone",
                text: snapshot.timeZoneName,
                style: mood
            )

            PopupInfoChip(
                icon: "arrow.left.arrow.right.circle.fill",
                title: "Difference",
                text: snapshot.differenceText,
                style: mood
            )
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(mood.gradient)
                    .opacity(0.94)
            }
            .overlay {
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(mood.primaryGlow.opacity(0.34))
                            .frame(width: proxy.size.width * 0.72)
                            .blur(radius: 58)
                            .offset(x: proxy.size.width * 0.20, y: -proxy.size.height * 0.18)

                        Circle()
                            .fill(mood.secondaryGlow.opacity(0.24))
                            .frame(width: proxy.size.width * 0.56)
                            .blur(radius: 48)
                            .offset(x: -proxy.size.width * 0.20, y: proxy.size.height * 0.26)

                        if mood.kind == .night {
                            SelectedCityStars()
                                .opacity(0.58)
                        }

                        if mood.kind == .evening || mood.kind == .morning {
                            Capsule()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: proxy.size.width * 0.48, height: 28)
                                .blur(radius: 14)
                                .offset(x: proxy.size.width * 0.06, y: proxy.size.height * 0.10)
                        }

                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.24), Color.clear, Color.black.opacity(0.14)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.24), Color.white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

private struct PopupInfoChip: View {
    let icon: String
    let title: String
    let text: String
    let style: TimeMoodTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.7))

            Text(text)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(style.kind == .night ? 0.08 : 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct SelectedCityStars: View {
    private let points: [CGPoint] = [
        .init(x: 0.14, y: 0.16), .init(x: 0.28, y: 0.10), .init(x: 0.74, y: 0.14),
        .init(x: 0.84, y: 0.24), .init(x: 0.18, y: 0.54), .init(x: 0.88, y: 0.58),
        .init(x: 0.64, y: 0.72), .init(x: 0.30, y: 0.82)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.72 : 0.34))
                        .frame(width: index.isMultiple(of: 3) ? 3 : 2, height: index.isMultiple(of: 3) ? 3 : 2)
                        .blur(radius: index.isMultiple(of: 3) ? 0.8 : 0)
                        .position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
                }
            }
        }
    }
}

private struct TimeMoodTheme {
    enum Kind {
        case morning
        case day
        case evening
        case night
    }

    let kind: Kind
    let gradient: LinearGradient
    let primaryGlow: Color
    let secondaryGlow: Color
    let shadowColor: Color
    let iconName: String
    let heroIconName: String
    let iconColor: Color
    let symbolBackground: RadialGradient
    let accentColor: Color
    let title: String

    init(snapshot: LocationTimeSnapshot, now: Date = .now) {
        let timeZone = TimeZone(identifier: snapshot.location.timeZoneIdentifier) ?? .current
        let hour = Calendar.current.dateComponents(in: timeZone, from: now).hour ?? 12

        switch hour {
        case 5..<10:
            kind = .morning
            gradient = LinearGradient(
                colors: [
                    Color(red: 0.23, green: 0.44, blue: 0.94),
                    Color(red: 0.52, green: 0.79, blue: 0.99),
                    TimeMapPalette.sunrise.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            primaryGlow = TimeMapPalette.sunrise
            secondaryGlow = TimeMapPalette.cloud
            shadowColor = TimeMapPalette.electricBlue.opacity(0.30)
            iconName = "sunrise.fill"
            heroIconName = "sunrise.circle.fill"
            iconColor = Color(red: 1.0, green: 0.86, blue: 0.54)
            symbolBackground = RadialGradient(
                colors: [Color(red: 1.0, green: 0.91, blue: 0.65), TimeMapPalette.sunrise, Color.clear],
                center: .center,
                startRadius: 8,
                endRadius: 70
            )
            accentColor = TimeMapPalette.sunrise
            title = "Morning glow"

        case 10..<17:
            kind = .day
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.electricBlue.opacity(0.98),
                    TimeMapPalette.cyan.opacity(0.92),
                    Color(red: 0.56, green: 0.84, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            primaryGlow = TimeMapPalette.cloud
            secondaryGlow = TimeMapPalette.cyan
            shadowColor = TimeMapPalette.electricBlue.opacity(0.26)
            iconName = "sun.max.fill"
            heroIconName = "sun.max.circle.fill"
            iconColor = Color(red: 1.0, green: 0.93, blue: 0.58)
            symbolBackground = RadialGradient(
                colors: [Color.white.opacity(0.95), Color(red: 1.0, green: 0.88, blue: 0.46), Color.clear],
                center: .center,
                startRadius: 4,
                endRadius: 64
            )
            accentColor = TimeMapPalette.cyan
            title = "Daytime now"

        case 17..<20:
            kind = .evening
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.indigo.opacity(0.96),
                    TimeMapPalette.violet.opacity(0.90),
                    TimeMapPalette.sunrise.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            primaryGlow = TimeMapPalette.sunrise
            secondaryGlow = TimeMapPalette.violet
            shadowColor = TimeMapPalette.violet.opacity(0.30)
            iconName = "sun.horizon.fill"
            heroIconName = "sun.horizon.circle.fill"
            iconColor = Color(red: 1.0, green: 0.80, blue: 0.50)
            symbolBackground = RadialGradient(
                colors: [Color(red: 1.0, green: 0.82, blue: 0.52), TimeMapPalette.sunrise, Color.clear],
                center: .center,
                startRadius: 8,
                endRadius: 64
            )
            accentColor = TimeMapPalette.sunrise
            title = "Evening light"

        default:
            kind = .night
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.night.opacity(0.98),
                    TimeMapPalette.deepOcean.opacity(0.96),
                    TimeMapPalette.violet.opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            primaryGlow = TimeMapPalette.violet
            secondaryGlow = TimeMapPalette.cyan
            shadowColor = TimeMapPalette.night.opacity(0.52)
            iconName = "moon.stars.fill"
            heroIconName = "moon.stars.circle.fill"
            iconColor = Color(red: 0.86, green: 0.91, blue: 1.0)
            symbolBackground = RadialGradient(
                colors: [Color(red: 0.86, green: 0.91, blue: 1.0), Color(red: 0.47, green: 0.56, blue: 0.92), Color.clear],
                center: .center,
                startRadius: 6,
                endRadius: 68
            )
            accentColor = TimeMapPalette.violet
            title = "Nightfall now"
        }
    }
}
