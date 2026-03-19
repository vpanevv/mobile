import SwiftUI

struct CitySearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TimeMapGradient.aurora)
                    .frame(width: 34, height: 34)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Search cities")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TimeMapPalette.mutedCloud)

                TextField("Tokyo, Cape Town, London...", text: $text)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(TimeMapPalette.cloud.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .timeMapGlass(cornerRadius: 24, tint: TimeMapGradient.aurora)
    }
}
