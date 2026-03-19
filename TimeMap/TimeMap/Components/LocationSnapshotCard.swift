import SwiftUI

struct LocationSnapshotCard: View {
    let snapshot: LocationTimeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(TimeMapGradient.sunrise)
                        .frame(width: 54, height: 54)
                    Text(FlagUtility.emoji(for: snapshot.location.countryCode))
                        .font(.system(size: 27))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(snapshot.location.city)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(snapshot.location.country)
                        .font(.subheadline)
                        .foregroundStyle(TimeMapPalette.mutedCloud)
                }

                Spacer(minLength: 0)

                ComparisonBadge(text: snapshot.differenceText)
            }

            Text(snapshot.currentTimeText)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            HStack(spacing: 10) {
                SnapshotChip(icon: "calendar", text: snapshot.dateText)
                SnapshotChip(icon: "globe", text: snapshot.timeZoneName)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.location.timeZoneIdentifier)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TimeMapPalette.mutedCloud)

                Text(snapshot.comparisonText)
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.cloud)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .timeMapGlass(cornerRadius: TimeMapMetrics.mediumCorner, tint: TimeMapGradient.aurora)
    }
}

private struct ComparisonBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.10), in: Capsule())
    }
}

private struct SnapshotChip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08), in: Capsule())
            .lineLimit(1)
    }
}
