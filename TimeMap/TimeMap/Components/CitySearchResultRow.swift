import SwiftUI

struct CitySearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(TimeMapGradient.accent)
                    .frame(width: 48, height: 48)

                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(result.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(result.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.up.right.circle.fill")
                .font(.title3)
                .foregroundStyle(TimeMapGradient.chip)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
