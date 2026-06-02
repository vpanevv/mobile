import SwiftUI
import UIKit

// MARK: - OccasionStepView

struct OccasionStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @State private var appeared = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            // ── Progress ────────────────────────────────────────────────
            FlowProgressBar(currentStep: .occasion)
                .padding(.top, 16)
                .padding(.bottom, 28)

            // ── Title ───────────────────────────────────────────────────
            FlowStepTitle(title: "What's the occasion?", subtitle: "Pick one to begin")
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: appeared)
                .padding(.bottom, 28)

            // ── Grid ────────────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(HolidayType.allCases.enumerated()), id: \.element.id) { idx, occ in
                        OccasionTile(
                            occasion: occ,
                            isSelected: coordinator.occasion == occ
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                coordinator.occasion = occ
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.8)
                                .delay(Double(idx) * 0.04),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            Spacer(minLength: 0)

            // ── CTA ─────────────────────────────────────────────────────
            PrimaryFlowButton(
                label: "Continue",
                disabled: coordinator.occasion == nil
            ) {
                coordinator.goNext(.name)
            }
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

// MARK: - OccasionTile

private struct OccasionTile: View {
    let occasion: HolidayType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(occasion.accentColor.opacity(isSelected ? 0.22 : 0.12))
                        .frame(width: 60, height: 60)
                    Text(occasion.emoji)
                        .font(.system(size: 30))
                }

                Text(occasion.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? occasion.accentColor : .primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isSelected ? occasion.accentColor.opacity(0.7) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            )
            .shadow(
                color: isSelected ? occasion.accentColor.opacity(0.25) : .black.opacity(0.08),
                radius: isSelected ? 14 : 4
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
    }
}
