import SwiftUI
import UIKit

// MARK: - ToneStepView

struct ToneStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @State private var appeared = false
    @State private var toneChanged = false

    var body: some View {
        ZStack {
            FlowAmbientLayer()
            ParticleSystemView()

            VStack(spacing: 0) {
            // ── Progress ────────────────────────────────────────────────
            FlowProgressBar(currentStep: .tone)
                .padding(.top, 16)
                .padding(.bottom, 28)

            // ── Title ───────────────────────────────────────────────────
            FlowStepTitle(title: "How should it sound?", subtitle: "Slide to choose the tone")
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: appeared)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)

            // ── Large tone display ───────────────────────────────────────
            VStack(spacing: 12) {
                Text(coordinator.tone.emoji)
                    .font(.system(size: 52))
                    .contentTransition(.symbolEffect(.replace))
                    .id(coordinator.tone)

                Text(coordinator.tone.label)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(coordinator.tone.color)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: coordinator.tone)

                Text(toneDescription(coordinator.tone))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: coordinator.tone)
                    .padding(.horizontal, 32)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.08), value: appeared)
            .padding(.bottom, 36)

            // ── Slider ──────────────────────────────────────────────────
            ToneSlider(selectedTone: Binding(
                get: { coordinator.tone },
                set: { coordinator.tone = $0 }
            ))
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.14), value: appeared)

            Spacer()

            // ── CTA ─────────────────────────────────────────────────────
            PrimaryFlowButton(label: "Continue") {
                coordinator.goNext(.length)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.20), value: appeared)
            .padding(.bottom, 40)
            } // end VStack
        } // end ZStack
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
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

    private func toneDescription(_ tone: WishTone) -> String {
        switch tone {
        case .formal:       return "Refined and respectful"
        case .professional: return "Polished and composed"
        case .warm:         return "Sincere and heartfelt"
        case .friendly:     return "Casual, like a good friend"
        case .playful:      return "Light and cheerful"
        case .funny:        return "Humorous with a clever twist"
        }
    }
}
