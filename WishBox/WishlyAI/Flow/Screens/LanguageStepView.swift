import SwiftUI
import UIKit

// MARK: - LanguageStepView

struct LanguageStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @State private var appeared = false

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    /// Display order: English first, then remaining languages sorted by native name.
    private var orderedLanguages: [WishLanguage] {
        let rest = WishLanguage.allCases.filter { $0 != .english }.sorted { $0.nativeName < $1.nativeName }
        return [.english] + rest
    }

    var body: some View {
        ZStack {
            // ── Living atmosphere ────────────────────────────────────────
            FlowAmbientLayer()
            ParticleSystemView()

            // ── Content ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                FlowProgressBar(currentStep: .language)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                FlowStepTitle(
                    title: "Choose your language",
                    subtitle: "We'll write the wish in this language"
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: appeared)
                .padding(.bottom, 18)

                // ── Language grid ─────────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Array(orderedLanguages.enumerated()), id: \.element.id) { idx, lang in
                            LanguageTile(
                                language: lang,
                                isSelected: coordinator.language == lang
                            ) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    coordinator.language = lang
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.8)
                                    .delay(Double(idx) * 0.035),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                Spacer(minLength: 0)

                PrimaryFlowButton(label: "Continue") {
                    coordinator.goNext(.name)
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

// MARK: - LanguageTile

private struct LanguageTile: View {
    let language: WishLanguage
    let isSelected: Bool
    let action: () -> Void

    private let accent = Color(hex: 0xc084fc)

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 32))

                Text(language.nativeName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? accent : .primary.opacity(0.8))
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
                        isSelected ? accent.opacity(0.70) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            )
            .shadow(
                color: isSelected ? accent.opacity(0.25) : .black.opacity(0.06),
                radius: isSelected ? 12 : 3
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
    }
}
