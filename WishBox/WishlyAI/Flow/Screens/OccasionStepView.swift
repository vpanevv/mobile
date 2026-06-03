import SwiftUI
import UIKit

// MARK: - OccasionStepView

struct OccasionStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @State private var appeared = false

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ZStack {
            // ── Living atmosphere ────────────────────────────────────────
            FlowAmbientLayer()
            ParticleSystemView()

            // ── Content ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                FlowProgressBar(currentStep: .occasion)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                FlowStepTitle(title: "What's the occasion?", subtitle: "Pick one to begin")
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: appeared)
                    .padding(.bottom, 18)

                LazyVGrid(columns: columns, spacing: 10) {
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
                        .offset(y: appeared ? 0 : 16)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.8).delay(Double(idx) * 0.035),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 0)

                PrimaryFlowButton(label: "Continue", disabled: coordinator.occasion == nil) {
                    coordinator.goNext(.language)
                }
                .padding(.top, 14)
                .padding(.bottom, 36)
            }
        }
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { FlowGlassBackButton() }
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
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(occasion.accentColor.opacity(isSelected ? 0.20 : 0.10))
                        .frame(width: 42, height: 42)
                    Text(occasion.emoji).font(.system(size: 22))
                }
                Text(occasion.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? occasion.accentColor : .primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? occasion.accentColor.opacity(0.65) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            )
            .shadow(
                color: isSelected ? occasion.accentColor.opacity(0.22) : .black.opacity(0.06),
                radius: isSelected ? 12 : 3
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
    }
}
