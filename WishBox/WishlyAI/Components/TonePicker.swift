import SwiftUI

struct TonePicker: View {
    @Binding var selected: WishTone

    var body: some View {
        DropdownMenu(
            items: WishTone.allCases,
            selected: $selected,
            accentColor: selected.color
        ) { item, isSelected in
            HStack(spacing: 12) {
                // Colored icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(item.color.opacity(isSelected ? 0.22 : 0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: item.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(item.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? item.color : .primary.opacity(0.88))
                    Text(item.description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.75))
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
