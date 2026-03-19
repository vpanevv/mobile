import SwiftUI

struct CitySearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(TimeMapGradient.sunrise)
                    .frame(width: 46, height: 46)

                Image(systemName: "sparkles.map")
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)

                Text(result.subtitle)
                    .font(.footnote)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
            }

            Spacer()

            Image(systemName: "arrow.up.right.circle.fill")
                .font(.title3)
                .foregroundStyle(TimeMapPalette.cloud)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
