import SwiftUI

struct ModePickerBar: View {
    @Binding var selectedMode: TimeMapViewModel.Mode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(TimeMapViewModel.Mode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        selectedMode = mode
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(mode.rawValue, systemImage: mode.iconName)
                            .font(.subheadline.weight(.semibold))
                        Text(mode.subtitle)
                            .font(.caption)
                            .foregroundStyle(selectedMode == mode ? Color.white.opacity(0.86) : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(selectedMode == mode ? AnyShapeStyle(TimeMapGradient.chip) : AnyShapeStyle(Color.white.opacity(0.08)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(selectedMode == mode ? 0.20 : 0.10), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .timeMapCard()
    }
}
