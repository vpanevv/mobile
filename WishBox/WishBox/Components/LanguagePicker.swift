import SwiftUI

struct LanguagePicker: View {
    @Binding var selected: WishLanguage

    var body: some View {
        DropdownMenu(
            items: WishLanguage.allCases,
            selected: $selected,
            accentColor: Color.neonViolet
        ) { item, isSelected in
            HStack(spacing: 10) {
                Text(item.flag)
                    .font(.system(size: 16))
                Text(item.label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.neonViolet : .primary.opacity(0.85))
            }
        }
        .padding(.horizontal, 20)
    }
}
