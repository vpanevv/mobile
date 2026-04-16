import SwiftUI
import UIKit

struct HolidayPicker: View {
    @Binding var selected: HolidayType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HolidayType.allCases) { type in
                    let isSelected = selected == type
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                            selected = type
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(type.label)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? Color.neonCyan : .white.opacity(0.45))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            isSelected
                                ? Color.neonCyan.opacity(0.10)
                                : Color.white.opacity(0.04)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected
                                        ? Color.neonCyan.opacity(0.65)
                                        : Color.white.opacity(0.07),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isSelected ? Color.neonCyan.opacity(0.25) : .clear,
                            radius: 8
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
