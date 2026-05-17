import SwiftUI
import UIKit

/// Generic push-down dropdown. The row closure receives (item, isSelected).
struct DropdownMenu<Item: Identifiable & Equatable, Row: View>: View {
    let items: [Item]
    @Binding var selected: Item
    let accentColor: Color
    @ViewBuilder let row: (Item, Bool) -> Row

    @State private var expanded = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            // ── Trigger row ────────────────────────────────────────────
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    row(selected, true)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accentColor.opacity(0.7))
                        .rotationEffect(.degrees(expanded ? -180 : 0))
                        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: expanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // ── Option list ────────────────────────────────────────────
            if expanded {
                Divider()
                    .background(accentColor.opacity(0.18))

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let isSelected = item == selected

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selected = item
                                expanded = false
                            }
                        } label: {
                            HStack(spacing: 12) {
                                row(item, isSelected)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(accentColor)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(isSelected ? accentColor.opacity(0.07) : Color.clear)
                        }
                        .buttonStyle(.plain)

                        if index < items.count - 1 {
                            Divider()
                                .background(Color.primary.opacity(0.06))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .transition(
                    .opacity.combined(with: .move(edge: .top))
                )
            }
        }
        .background(
            scheme == .dark
                ? Color.surface.opacity(0.95)
                : Color(UIColor.systemBackground).opacity(0.95)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(expanded ? 0.55 : 0.30),
                            Color.neonViolet.opacity(expanded ? 0.35 : 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: accentColor.opacity(expanded ? 0.14 : 0.07), radius: expanded ? 18 : 10)
    }
}
