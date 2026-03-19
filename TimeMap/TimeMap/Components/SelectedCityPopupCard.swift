import SwiftUI

struct SelectedCityPopupCard: View {
    let snapshot: LocationTimeSnapshot
    let dismiss: () -> Void

    private var theme: SelectedCityCardTheme {
        SelectedCityCardTheme(for: snapshot)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            header
            heroMoment
            metadataChips
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 26)
        .frame(maxWidth: 420, minHeight: 360, maxHeight: 470, alignment: .topLeading)
        .background(cardBackground)
        .overlay(cardStroke)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: theme.shadowColor, radius: 38, y: 24)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(theme.mode == .night ? 0.10 : 0.18))
                        .frame(width: 56, height: 56)

                    Text(FlagUtility.emoji(for: snapshot.location.countryCode))
                        .font(.system(size: 32))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(snapshot.location.city)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Image(systemName: theme.iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.iconColor)
                    }

                    Text(snapshot.location.country)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                }
            }

            Spacer(minLength: 12)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(theme.mode == .night ? 0.09 : 0.16), in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var heroMoment: some View {
        VStack(spacing: 18) {
            Text(snapshot.currentTimeText)
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.iconColor)

                Text(theme.modeTitle)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.white.opacity(theme.mode == .night ? 0.10 : 0.16), in: Capsule())
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )

            VStack(spacing: 6) {
                Text("Current time in \(snapshot.location.city)")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.80))

                Text(snapshot.dateText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private var metadataChips: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                PopupInfoChip(
                    icon: "globe.americas.fill",
                    title: "Timezone",
                    text: snapshot.timeZoneName,
                    style: theme
                )

                PopupInfoChip(
                    icon: "arrow.left.arrow.right.circle.fill",
                    title: "Difference",
                    text: snapshot.differenceText,
                    style: theme
                )
            }

            PopupPillRow(
                icon: "location.circle.fill",
                text: snapshot.location.timeZoneIdentifier,
                style: theme
            )
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(theme.gradient)
                    .opacity(theme.mode == .night ? 0.92 : 0.86)
            }
            .overlay {
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(theme.primaryGlow.opacity(theme.mode == .night ? 0.34 : 0.22))
                            .frame(width: proxy.size.width * 0.7)
                            .blur(radius: 54)
                            .offset(x: proxy.size.width * 0.18, y: -proxy.size.height * 0.18)

                        Circle()
                            .fill(theme.secondaryGlow.opacity(theme.mode == .night ? 0.22 : 0.26))
                            .frame(width: proxy.size.width * 0.52)
                            .blur(radius: 44)
                            .offset(x: -proxy.size.width * 0.22, y: proxy.size.height * 0.28)

                        if theme.mode == .night {
                            SelectedCityStars()
                                .opacity(0.55)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.20))
                                .frame(width: proxy.size.width * 0.46)
                                .blur(radius: 34)
                                .offset(x: proxy.size.width * 0.2, y: -proxy.size.height * 0.16)
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
    let style: SelectedCityCardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.68))

            Text(text)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(style.mode == .night ? 0.08 : 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct PopupPillRow: View {
    let icon: String
    let text: String
    let style: SelectedCityCardTheme

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.white.opacity(0.82))
            .lineLimit(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(style.mode == .night ? 0.08 : 0.13))
                    .overlay(
                        Capsule(style: .continuous)
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
                        .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.72 : 0.36))
                        .frame(width: index.isMultiple(of: 3) ? 3 : 2, height: index.isMultiple(of: 3) ? 3 : 2)
                        .blur(radius: index.isMultiple(of: 3) ? 0.8 : 0)
                        .position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
                }
            }
        }
    }
}

private struct SelectedCityCardTheme {
    enum Mode {
        case day
        case night
    }

    let mode: Mode
    let gradient: LinearGradient
    let primaryGlow: Color
    let secondaryGlow: Color
    let shadowColor: Color
    let iconName: String
    let iconColor: Color

    var modeTitle: String {
        mode == .night ? "Night in the city" : "Daytime now"
    }

    init(for snapshot: LocationTimeSnapshot, now: Date = .now) {
        let timeZone = TimeZone(identifier: snapshot.location.timeZoneIdentifier) ?? .current
        let hour = Calendar.current.dateComponents(in: timeZone, from: now).hour ?? 12
        let isDaytime = (6..<18).contains(hour)

        if isDaytime {
            mode = .day
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.electricBlue.opacity(0.98),
                    TimeMapPalette.cyan.opacity(0.92),
                    TimeMapPalette.sunrise.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            primaryGlow = TimeMapPalette.cloud
            secondaryGlow = TimeMapPalette.sunrise
            shadowColor = TimeMapPalette.electricBlue.opacity(0.30)
            iconName = "sun.max.fill"
            iconColor = Color(red: 1.0, green: 0.86, blue: 0.44)
        } else {
            mode = .night
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.night.opacity(0.98),
                    TimeMapPalette.deepOcean.opacity(0.96),
                    TimeMapPalette.violet.opacity(0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            primaryGlow = TimeMapPalette.violet
            secondaryGlow = TimeMapPalette.cyan
            shadowColor = TimeMapPalette.night.opacity(0.52)
            iconName = "moon.stars.fill"
            iconColor = Color(red: 0.86, green: 0.91, blue: 1.0)
        }
    }
}
