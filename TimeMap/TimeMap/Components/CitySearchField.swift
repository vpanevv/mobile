import SwiftUI

struct CitySearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TimeMapGradient.chip)
                    .frame(width: 30, height: 30)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Search cities")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Tokyo, London, New York...", text: $text)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.body.weight(.medium))
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .timeMapCard()
    }
}
