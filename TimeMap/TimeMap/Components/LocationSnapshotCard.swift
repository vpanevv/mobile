import SwiftUI

struct LocationSnapshotCard: View {
    let snapshot: LocationTimeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(TimeMapGradient.accent)
                        .frame(width: 48, height: 48)
                    Text(FlagUtility.emoji(for: snapshot.location.countryCode))
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.location.city)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(snapshot.location.country)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer(minLength: 0)

                DifferenceBadge(text: snapshot.differenceText)
            }

            Text(snapshot.currentTimeText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            HStack(spacing: 10) {
                SnapshotInfoPill(icon: "calendar", text: snapshot.dateText)
                SnapshotInfoPill(icon: "globe", text: snapshot.timeZoneName)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.location.timeZoneIdentifier)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.68))

                Text(snapshot.comparisonText)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            TimeMapPalette.twilight.opacity(0.92),
                            TimeMapPalette.midnight.opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: TimeMapPalette.shadow, radius: 24, y: 14)
        )
    }
}

private struct DifferenceBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.10), in: Capsule())
            .foregroundStyle(.white)
    }
}

private struct SnapshotInfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.08), in: Capsule())
            .foregroundStyle(Color.white.opacity(0.90))
            .lineLimit(1)
    }
}
