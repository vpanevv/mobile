import SwiftUI
import UIKit

// MARK: - Section header

private struct SelectorHeader: View {
    let title: String
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Tone card

struct ToneCard: View {
    let tone: WishTone
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: tone.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tone.color)

                Text(tone.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(tone.description)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(width: 90, height: 96)
            .background(
                ZStack {
                    if isSelected {
                        tone.color.opacity(0.15)
                    }
                }
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? tone.color : Color.primary.opacity(0.10),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? tone.color.opacity(0.4) : .clear,
                radius: 12, y: 4
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tone selector

struct ToneSelectorView: View {
    @Binding var selectedTone: WishTone

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SelectorHeader(
                title: "Tone",
                icon: selectedTone.icon,
                label: selectedTone.rawValue,
                color: selectedTone.color
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WishTone.allCases) { tone in
                        ToneCard(tone: tone, isSelected: selectedTone == tone) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                selectedTone = tone
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
}
