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
                Text(item.emoji)
                    .font(.system(size: 18))
                    .frame(width: 22)
                Text(item.label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.neonCyan : .primary.opacity(0.85))
            }
        }
        .padding(.horizontal, 20)
    }
}
