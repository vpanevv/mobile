import SwiftUI

struct SelectedCityPopupCard: View {
    let snapshot: LocationTimeSnapshot
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    let dismiss: () -> Void

    @State private var animateMood = false

    private var mood: TimeMoodTheme {
        TimeMoodTheme(snapshot: snapshot)
    }

    private var connectionRecommendation: ConnectionRecommendation {
        ConnectionRecommendationService.makeRecommendation(for: snapshot.location)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            cardContent(using: .regular)
            cardContent(using: .compact)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 22)
        .frame(maxWidth: 420, alignment: .topLeading)
        .background(cardBackground)
        .overlay(cardStroke)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: mood.shadowColor, radius: 40, y: 24)
        .onAppear {
            animateMood = true
        }
    }

    @ViewBuilder
    private func cardContent(using layout: CardLayout) -> some View {
        VStack(alignment: .leading, spacing: layout.verticalSpacing) {
            header(layout: layout)
            heroMoodMoment(layout: layout)
            metricsRow(layout: layout)
            connectionRow(layout: layout)
        }
    }

    private func header(layout: CardLayout) -> some View {
        VStack(spacing: layout.headerSpacing) {
            HStack(alignment: .top, spacing: 16) {
                HStack(alignment: .center, spacing: layout.flagSpacing) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: layout.flagSize, height: layout.flagSize)

                        Text(FlagUtility.emoji(for: snapshot.location.countryCode))
                            .font(.system(size: layout.flagEmojiSize))
                    }
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(snapshot.location.city)
                            .font(.system(size: layout.cityFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(snapshot.location.country)
                            .font(layout.countryFont)
                            .foregroundStyle(Color.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                HStack(spacing: 10) {
                    favoriteButton

                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: layout.controlIconSize, weight: .bold))
                            .foregroundStyle(.white.opacity(0.88))
                            .frame(width: layout.controlSize, height: layout.controlSize)
                            .background(Color.white.opacity(0.12), in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.plain)
            }

            Text(snapshot.dateText)
                .font(layout.dateFont)
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func heroMoodMoment(layout: CardLayout) -> some View {
        VStack(spacing: layout.heroSpacing) {
            moodSymbol(layout: layout)

            Text(snapshot.currentTimeText)
                .font(.system(size: layout.timeFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .contentTransition(.numericText())
                .multilineTextAlignment(.center)

            VStack(spacing: 7) {
                HStack(spacing: 10) {
                    Image(systemName: mood.iconName)
                        .font(.system(size: layout.moodIconSize, weight: .semibold))
                        .foregroundStyle(mood.iconColor)

                    Text(mood.title)
                        .font(.system(size: layout.moodTitleSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, layout.moodCapsuleHorizontalPadding)
                .padding(.vertical, layout.moodCapsuleVerticalPadding)
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

    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isFavorite ? Color(red: 1.0, green: 0.84, blue: 0.88) : .white.opacity(0.88))
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isFavorite ? Color.white.opacity(0.22) : Color.white.opacity(0.12))
                )
                .overlay(
                    Circle()
                        .strokeBorder(isFavorite ? Color.white.opacity(0.28) : Color.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: isFavorite ? Color(red: 1.0, green: 0.58, blue: 0.70).opacity(0.35) : .clear, radius: 16, y: 8)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    private func moodSymbol(layout: CardLayout) -> some View {
        ZStack {
            Circle()
                .fill(mood.symbolBackground)
                .frame(width: layout.symbolSize, height: layout.symbolSize)
                .blur(radius: 2)
                .scaleEffect(animateMood ? 1.02 : 0.98)
                .opacity(animateMood ? 1 : 0.92)

            Circle()
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                .frame(width: layout.symbolRingSize, height: layout.symbolRingSize)

            Image(systemName: mood.heroIconName)
                .font(.system(size: layout.heroIconSize + (mood.kind == .night ? 3 : 0), weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(mood.iconColor)
                .offset(y: animateMood ? -2 : 2)
                .shadow(color: mood.iconColor.opacity(0.28), radius: 12)
        }
        .frame(height: layout.symbolFrameHeight)
        .animation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true), value: animateMood)
    }

    private func metricsRow(layout: CardLayout) -> some View {
        Group {
            if layout.isCompact {
                VStack(spacing: 10) {
                    popupInfoChip(title: "Timezone", icon: "globe.americas.fill", text: snapshot.timeZoneName, layout: layout)
                    popupInfoChip(title: "Difference", icon: "arrow.left.arrow.right.circle.fill", text: snapshot.differenceText, layout: layout)
                }
            } else {
                HStack(spacing: 10) {
                    popupInfoChip(title: "Timezone", icon: "globe.americas.fill", text: snapshot.timeZoneName, layout: layout)
                    popupInfoChip(title: "Difference", icon: "arrow.left.arrow.right.circle.fill", text: snapshot.differenceText, layout: layout)
                }
            }
        }
    }

    private func connectionRow(layout: CardLayout) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "phone.badge.waveform.fill")
                .font(.system(size: layout.connectionIconSize, weight: .semibold))
                .foregroundStyle(mood.iconColor)
                .frame(width: layout.connectionBadgeSize, height: layout.connectionBadgeSize)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: layout.connectionCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(connectionRecommendation.title)
                    .font(layout.connectionTitleFont)
                    .foregroundStyle(Color.white.opacity(0.72))

                Text(connectionRecommendation.timeText)
                    .font(layout.connectionTimeFont)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(connectionRecommendation.detailText)
                    .font(layout.connectionDetailFont)
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, layout.connectionHorizontalPadding)
        .padding(.vertical, layout.connectionVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(mood.kind == .night ? 0.08 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        )
    }

    private func popupInfoChip(title: String, icon: String, text: String, layout: CardLayout) -> some View {
        PopupInfoChip(
            icon: icon,
            title: title,
            text: text,
            style: mood,
            layout: layout
        )
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
    let layout: CardLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(layout.chipLabelFont)
                .foregroundStyle(Color.white.opacity(0.7))

            Text(text)
                .font(layout.chipTextFont)
                .foregroundStyle(.white)
                .lineLimit(layout.isCompact ? 1 : 2)
                .minimumScaleFactor(0.8)
        }
        .padding(layout.chipPadding)
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

private struct CardLayout {
    let isCompact: Bool
    let verticalSpacing: CGFloat
    let headerSpacing: CGFloat
    let flagSpacing: CGFloat
    let flagSize: CGFloat
    let flagEmojiSize: CGFloat
    let cityFontSize: CGFloat
    let countryFont: Font
    let dateFont: Font
    let controlSize: CGFloat
    let controlIconSize: CGFloat
    let heroSpacing: CGFloat
    let symbolSize: CGFloat
    let symbolRingSize: CGFloat
    let symbolFrameHeight: CGFloat
    let heroIconSize: CGFloat
    let timeFontSize: CGFloat
    let moodIconSize: CGFloat
    let moodTitleSize: CGFloat
    let moodCapsuleHorizontalPadding: CGFloat
    let moodCapsuleVerticalPadding: CGFloat
    let chipPadding: CGFloat
    let chipLabelFont: Font
    let chipTextFont: Font
    let connectionIconSize: CGFloat
    let connectionBadgeSize: CGFloat
    let connectionCornerRadius: CGFloat
    let connectionTitleFont: Font
    let connectionTimeFont: Font
    let connectionDetailFont: Font
    let connectionHorizontalPadding: CGFloat
    let connectionVerticalPadding: CGFloat

    static let regular = CardLayout(
        isCompact: false,
        verticalSpacing: 18,
        headerSpacing: 12,
        flagSpacing: 14,
        flagSize: 54,
        flagEmojiSize: 30,
        cityFontSize: 28,
        countryFont: .title3.weight(.medium),
        dateFont: .subheadline.weight(.medium),
        controlSize: 34,
        controlIconSize: 13,
        heroSpacing: 12,
        symbolSize: 92,
        symbolRingSize: 102,
        symbolFrameHeight: 106,
        heroIconSize: 31,
        timeFontSize: 60,
        moodIconSize: 16,
        moodTitleSize: 21,
        moodCapsuleHorizontalPadding: 18,
        moodCapsuleVerticalPadding: 10,
        chipPadding: 14,
        chipLabelFont: .caption.weight(.semibold),
        chipTextFont: .headline.weight(.semibold),
        connectionIconSize: 17,
        connectionBadgeSize: 40,
        connectionCornerRadius: 14,
        connectionTitleFont: .caption.weight(.semibold),
        connectionTimeFont: .headline.weight(.semibold),
        connectionDetailFont: .caption,
        connectionHorizontalPadding: 15,
        connectionVerticalPadding: 12
    )

    static let compact = CardLayout(
        isCompact: true,
        verticalSpacing: 14,
        headerSpacing: 10,
        flagSpacing: 12,
        flagSize: 48,
        flagEmojiSize: 27,
        cityFontSize: 24,
        countryFont: .subheadline.weight(.medium),
        dateFont: .caption.weight(.medium),
        controlSize: 32,
        controlIconSize: 12,
        heroSpacing: 10,
        symbolSize: 76,
        symbolRingSize: 84,
        symbolFrameHeight: 86,
        heroIconSize: 27,
        timeFontSize: 50,
        moodIconSize: 14,
        moodTitleSize: 18,
        moodCapsuleHorizontalPadding: 16,
        moodCapsuleVerticalPadding: 9,
        chipPadding: 13,
        chipLabelFont: .caption2.weight(.semibold),
        chipTextFont: .subheadline.weight(.semibold),
        connectionIconSize: 16,
        connectionBadgeSize: 36,
        connectionCornerRadius: 13,
        connectionTitleFont: .caption2.weight(.semibold),
        connectionTimeFont: .subheadline.weight(.semibold),
        connectionDetailFont: .caption2,
        connectionHorizontalPadding: 14,
        connectionVerticalPadding: 11
    )
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
