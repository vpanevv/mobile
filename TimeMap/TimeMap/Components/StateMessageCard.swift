import SwiftUI

struct StateMessageCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(TimeMapGradient.aurora)
                    .frame(width: 44, height: 44)
                    .shadow(color: TimeMapPalette.electricBlue.opacity(0.28), radius: 14, y: 8)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .timeMapGlass(cornerRadius: TimeMapMetrics.mediumCorner, tint: TimeMapGradient.aurora)
    }
}
