import SwiftUI

struct HolidayPicker: View {
    @Binding var selected: HolidayType

    var body: some View {
        DropdownMenu(
            items: HolidayType.allCases,
            selected: $selected,
            accentColor: Color.neonCyan
        ) { item, isSelected in
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Color.neonCyan : .primary.opacity(0.5))
                    .frame(width: 22)
                Text(item.label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.neonCyan : .primary.opacity(0.85))
            }
        }
        .padding(.horizontal, 20)
    }
}
