import SwiftUI

struct ModePickerBar: View {
    @Binding var selectedMode: TimeMapViewModel.Mode
    @Namespace private var selectionAnimation

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimeMapViewModel.Mode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                        selectedMode = mode
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(mode.rawValue, systemImage: mode.iconName)
                            .font(.subheadline.weight(.semibold))
                        Text(mode.subtitle)
                            .font(.caption)
                            .foregroundStyle(selectedMode == mode ? Color.white.opacity(0.82) : TimeMapPalette.mutedCloud)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background {
                        if selectedMode == mode {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(TimeMapGradient.aurora)
                                .matchedGeometryEffect(id: "mode", in: selectionAnimation)
                        } else {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .timeMapGlass(cornerRadius: 24, tint: TimeMapGradient.aurora)
    }
}
