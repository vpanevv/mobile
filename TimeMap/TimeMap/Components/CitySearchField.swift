import SwiftUI

struct CitySearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(TimeMapGradient.aurora)
                    .frame(width: 42, height: 42)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Search cities")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TimeMapPalette.mutedCloud)

                TextField("Tokyo, Cape Town, London...", text: $text)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(TimeMapPalette.cloud.opacity(0.74))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .timeMapGlass(cornerRadius: 28, tint: TimeMapGradient.aurora)
    }
}
