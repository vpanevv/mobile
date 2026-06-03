import SwiftUI
import UIKit

// MARK: - ResultStepView

struct ResultStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @EnvironmentObject private var store:       FavoritesStore

    @State private var cardAppeared  = false
    @State private var copied        = false
    @State private var heartScale    = 1.0
    @State private var heartBurst    = false
    @State private var showCardEditor = false
    @State private var displayedText  = ""
    @State private var isTyping       = false
    @State private var typewriterTask: Task<Void, Never>?

    private var wish: String { coordinator.generatedWish ?? "" }
    private var isFav: Bool  { store.isFavorite(text: wish) }

    var body: some View {
        ZStack {
            FlowAmbientLayer()
            ParticleSystemView()

            VStack(spacing: 0) {
            // ── Progress ────────────────────────────────────────────────
            FlowProgressBar(currentStep: .result)
                .padding(.top, 16)
                .padding(.bottom, 28)

            // ── Title ───────────────────────────────────────────────────
            Text("Here's your wish 🎁")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .opacity(cardAppeared ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: cardAppeared)
                .padding(.bottom, 20)
                .padding(.horizontal, 24)

            // ── Wish card ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 20) {
                // Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(isTyping ? Color.neonCyan : Color.neonCyan.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .shadow(color: isTyping ? Color.neonCyan.opacity(0.8) : .clear, radius: 4)
                    Text(isTyping ? "GENERATING" : "AI GENERATED")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.neonCyan.opacity(0.75))
                        .tracking(2)
                    Spacer()
                    if isTyping {
                        ProgressView().tint(Color.neonCyan).scaleEffect(0.6)
                    }
                }

                // Wish text
                ScrollView(showsIndicators: false) {
                    Text(displayedText + (isTyping ? "▋" : ""))
                        .font(.system(size: 19, weight: .regular, design: .rounded))
                        .italic()
                        .foregroundStyle(.primary.opacity(0.92))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .animation(nil, value: displayedText)
                }
                .frame(maxHeight: 240)
            }
            .padding(22)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.neonCyan.opacity(0.40), Color.neonViolet.opacity(0.25)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.neonCyan.opacity(0.10), radius: 20, y: 4)
            .overlay(alignment: .topTrailing) {
                heartButton.padding(14)
            }
            .scaleEffect(cardAppeared ? 1 : 0.92)
            .opacity(cardAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.05), value: cardAppeared)
            .padding(.horizontal, 24)

            // ── Action row ────────────────────────────────────────────────
            if !isTyping {
                HStack(spacing: 24) {
                    // Copy
                    GlassCircleButton(
                        icon: copied ? "checkmark" : "doc.on.doc",
                        tint: copied ? .green : Color.neonCyan,
                        isActive: copied
                    ) {
                        UIPasteboard.general.string = wish
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copied = false }
                        }
                    }

                    // Create Card
                    GlassCircleButton(icon: "wand.and.stars", tint: Color(hex: 0xc084fc)) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showCardEditor = true
                    }
                }
                .padding(.top, 24)
                .opacity(cardAppeared ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.25), value: cardAppeared)
            }

            Spacer()

            // ── Bottom actions ────────────────────────────────────────────
            VStack(spacing: 14) {
                // Regenerate
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // Pop result, push generating again
                    coordinator.path.removeLast()
                    coordinator.generatedWish = nil
                    coordinator.goNext(.generating)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise")
                            .font(.system(size: 13, weight: .medium))
                        Text("Regenerate")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.primary.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)

                // Start Over
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        coordinator.reset()
                    }
                } label: {
                    Text("Start Over")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 40)
            .opacity(cardAppeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.30), value: cardAppeared)
            } // end VStack
        } // end ZStack
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { cardAppeared = true }
            }
            startTypewriter()
        }
        .fullScreenCover(isPresented: $showCardEditor) {
            CardEditorView(
                wishText: wish,
                occasion: coordinator.occasion?.rawValue ?? "",
                recipientName: coordinator.recipientNameForDisplay
            )
        }
    }

    // MARK: - Heart button

    private var heartButton: some View {
        Button {
            store.toggle(
                text: wish,
                occasion: coordinator.occasion ?? .birthday,
                tone: coordinator.tone,
                length: coordinator.length,
                recipientName: coordinator.recipientNameForDisplay
            )
            if store.isFavorite(text: wish) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { heartScale = 1.45 }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6).delay(0.15)) { heartScale = 0.9 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7).delay(0.35)) { heartScale = 1.0 }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .frame(width: 38, height: 38)
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isFav ? Color(hex: 0xf43f5e) : Color.white.opacity(0.7))
                    .scaleEffect(heartScale)
            }
        }
        .buttonStyle(.plain)
        .overlay { if heartBurst { HeartBurstView() } }
    }

    // MARK: - Typewriter

    private func startTypewriter() {
        typewriterTask?.cancel()
        displayedText = ""
        isTyping = true
        typewriterTask = Task {
            for char in wish {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: 20_000_000)
                guard !Task.isCancelled else { break }
                displayedText.append(char)
            }
            isTyping = false
        }
    }
}
