import SwiftUI
import UIKit

// MARK: - Length card

struct LengthCard: View {
    let length: WishLength
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Image(systemName: length.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(length.color)

                Text(length.rawValue)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(length.subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                ZStack {
                    if isSelected {
                        length.color.opacity(0.15)
                    }
                }
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? length.color : Color.primary.opacity(0.10),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? length.color.opacity(0.35) : .clear,
                radius: 10, y: 3
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Length selector

struct WishLengthSelectorView: View {
    @Binding var selectedLength: WishLength

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Wish Length")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: selectedLength.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selectedLength.color)
                    Text(selectedLength.rawValue)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(selectedLength.color)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(selectedLength.color.opacity(0.14))
                .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(WishLength.allCases) { length in
                    LengthCard(length: length, isSelected: selectedLength == length) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            selectedLength = length
                        }
                    }
                }
            }
        }
    }
}
