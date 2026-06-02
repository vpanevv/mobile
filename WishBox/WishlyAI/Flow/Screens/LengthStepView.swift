import SwiftUI
import UIKit

// MARK: - LengthStepView

struct LengthStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Progress ────────────────────────────────────────────────
            FlowProgressBar(currentStep: .length)
                .padding(.top, 16)
                .padding(.bottom, 28)

            // ── Title ───────────────────────────────────────────────────
            FlowStepTitle(title: "How long?", subtitle: "Pick the format you'll send")
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: appeared)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

            // ── Cards ───────────────────────────────────────────────────
            VStack(spacing: 14) {
                ForEach(Array(WishLength.allCases.enumerated()), id: \.element.id) { idx, length in
                    FlowLengthCard(
                        length: length,
                        isSelected: coordinator.length == length
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            coordinator.length = length
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.8)
                            .delay(Double(idx) * 0.07),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // ── CTA ─────────────────────────────────────────────────────
            PrimaryFlowButton(label: "Generate Wish ✨", icon: "sparkles") {
                coordinator.goNext(.generating)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.24), value: appeared)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                FlowGlassBackButton()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { appeared = true }
            }
        }
    }
}

// MARK: - FlowLengthCard

private struct FlowLengthCard: View {
    let length: WishLength
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(length.color.opacity(isSelected ? 0.22 : 0.10))
                        .frame(width: 52, height: 52)
                    Image(systemName: length.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isSelected ? length.color : length.color.opacity(0.65))
                }

                // Labels
                VStack(alignment: .leading, spacing: 4) {
                    Text(length.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(length.subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? length.color : Color.white.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(length.color)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSelected ? length.color.opacity(0.60) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            )
            .shadow(
                color: isSelected ? length.color.opacity(0.22) : .black.opacity(0.06),
                radius: isSelected ? 14 : 3
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
    }
}
