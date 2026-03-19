import SwiftUI

struct LocalTimeHeroCard: View {
    let info: LocalTimeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TIME MAP")
                        .font(.caption.weight(.bold))
                        .tracking(2.4)
                        .foregroundStyle(Color.white.opacity(0.82))

                    Text("Your Local Time")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Label("Live", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.14), in: Capsule())
                    .foregroundStyle(.white)
            }

            Text(info.currentTimeText)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            HStack(spacing: 10) {
                LocalHeroPill(icon: "location.fill", text: info.placeLabel)
                LocalHeroPill(icon: "calendar", text: info.dateText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(info.timeZoneName, systemImage: "globe.americas.fill")
                Text(info.timeZoneIdentifier)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .padding(.leading, 2)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .timeMapHeroCard()
    }
}

private struct LocalHeroPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12), in: Capsule())
            .foregroundStyle(.white)
            .lineLimit(1)
    }
}
