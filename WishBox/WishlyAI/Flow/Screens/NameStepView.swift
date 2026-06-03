import SwiftUI
import UIKit

// MARK: - NameStepView

struct NameStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @FocusState private var fieldFocused: Bool
    @FocusState private var secondFieldFocused: Bool
    @State private var appeared = false

    private var isNewBaby: Bool { coordinator.occasion == .newBaby }
    private var isWedding: Bool { coordinator.occasion == .wedding }

    var body: some View {
        ZStack {
            // ── Living atmosphere ────────────────────────────────────────
            FlowAmbientLayer()
            ParticleSystemView()

            // ── Content ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                FlowProgressBar(currentStep: .name)
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                FlowStepTitle(title: titleText, subtitle: subtitleText)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: appeared)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)

                Group {
                    if isNewBaby      { newBabyFields }
                    else if isWedding { weddingFields }
                    else              { standardField  }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.08), value: appeared)
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 14) {
                    PrimaryFlowButton(label: "Continue", disabled: !canContinue) {
                        fieldFocused = false
                        if !isNewBaby && !isWedding {
                            coordinator.includeName = !coordinator.name.trimmingCharacters(in: .whitespaces).isEmpty
                        }
                        coordinator.goNext(.tone)
                    }
                    SkipButton(label: "Skip — generate without a name") {
                        fieldFocused = false
                        coordinator.name = ""; coordinator.parentName = ""
                        coordinator.babyName = ""; coordinator.includeName = false
                        coordinator.goNext(.tone)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { FlowGlassBackButton() }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { withAnimation { appeared = true } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) { fieldFocused = true }
        }
    }

    // MARK: - Field layouts

    private var standardField: some View {
        VStack(spacing: 10) {
            GlassTextField(
                placeholder: "Their name", text: $coordinator.name,
                focused: $fieldFocused,
                font: .system(size: 22, weight: .medium, design: .rounded),
                textAlignment: .center
            ) {
                if !coordinator.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    coordinator.includeName = true
                    coordinator.goNext(.tone)
                }
            }
            Text("We'll use this to personalise the wish")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.35))
        }
    }

    private var newBabyFields: some View {
        VStack(spacing: 16) {
            GlassTextField(placeholder: "Parent's name (optional)", text: $coordinator.parentName, focused: $fieldFocused) {}
            GlassTextField(placeholder: "Baby's name (optional)",   text: $coordinator.babyName,   focused: $secondFieldFocused) {}
        }
    }

    private var weddingFields: some View {
        VStack(spacing: 16) {
            GlassTextField(placeholder: "Partner 1's name (optional)", text: $coordinator.name,       focused: $fieldFocused) {}
            GlassTextField(placeholder: "Partner 2's name (optional)", text: $coordinator.parentName, focused: $secondFieldFocused) {}
        }
    }

    // MARK: - Helpers

    private var titleText: String {
        if isNewBaby { return "Personalise this wish" }
        if isWedding { return "Who's getting married?" }
        return "Who is it for?"
    }

    private var subtitleText: String {
        if isNewBaby || isWedding { return "Both names are optional — skip what you don't need" }
        return "Add a name to make it personal — or skip"
    }

    private var canContinue: Bool { true }
}

// MARK: - GlassTextField

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    var font: Font = .system(size: 17, weight: .medium, design: .rounded)
    var textAlignment: TextAlignment = .leading
    let onSubmit: () -> Void

    var body: some View {
        TextField(placeholder, text: $text, axis: .horizontal)
            .font(font)
            .multilineTextAlignment(textAlignment)
            .focused(focused)
            .onSubmit(onSubmit)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}
