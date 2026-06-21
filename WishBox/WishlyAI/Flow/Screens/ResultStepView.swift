import SwiftUI
import UIKit
import Combine

// MARK: - ResultStepView
// The wish is STREAMED from the API into coordinator.generatedWish in uneven
// bursts. We never show those raw bursts — instead we buffer them and reveal
// the text at a smooth, organic "writing" pace (adaptive catch-up + punctuation
// rhythm + blinking caret + subtle haptic ticks) so it always feels like the
// wish is being written live in the moment.

struct ResultStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @EnvironmentObject private var store:       FavoritesStore
    @ObservedObject private var pro   = ProStore.shared
    @ObservedObject private var quota = WishQuota.shared

    @State private var cardAppeared   = false
    @State private var copied         = false
    @State private var heartScale     = 1.0
    @State private var heartBurst     = false
    @State private var showCardEditor = false
    @State private var showPaywall    = false
    @State private var paywallContext: PaywallContext = .cardMode

    // Live-writing reveal
    @State private var revealedCount  = 0
    @State private var caretVisible   = true

    private let blinkTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private let haptic = UISelectionFeedbackGenerator()

    private var fullText: String { coordinator.generatedWish ?? "" }
    private var displayed: String { String(fullText.prefix(revealedCount)) }
    /// True while we're still streaming OR still catching the reveal up to the buffer.
    private var isWriting: Bool { coordinator.isGenerating || revealedCount < fullText.count }
    private var isFav: Bool { store.isFavorite(text: fullText) }

    var body: some View {
        ZStack {
            FlowAmbientLayer()
            ParticleSystemView()

            VStack(spacing: 0) {
                // ── Progress ─────────────────────────────────────────────
                FlowProgressBar(currentStep: .result)
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                // ── Title ────────────────────────────────────────────────
                Text(isWriting ? "Writing your wish ✨" : "Here's your wish 🎁")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isWriting)
                    .opacity(cardAppeared ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: cardAppeared)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 24)

                // ── Wish card ────────────────────────────────────────────
                VStack(spacing: 18) {
                    // Badge — centered
                    HStack(spacing: 7) {
                        Circle()
                            .fill(isWriting ? Color.neonCyan : Color.neonCyan.opacity(0.6))
                            .frame(width: 7, height: 7)
                            .shadow(color: isWriting ? Color.neonCyan.opacity(0.8) : .clear, radius: 4)
                        Text(isWriting ? "GENERATING" : "AI GENERATED")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.neonCyan.opacity(0.85))
                            .tracking(2.5)
                            .contentTransition(.opacity)
                        if isWriting {
                            ProgressView().tint(Color.neonCyan).scaleEffect(0.55)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Live wish text + blinking caret (caret glyph always present,
                    // just transparent when off, so there is zero layout shift)
                    (
                        Text(displayed)
                        + Text("▋")
                            .foregroundColor(Color.neonCyan.opacity(isWriting && caretVisible ? 0.9 : 0.0))
                    )
                    .font(.system(size: 19, weight: .regular, design: .rounded))
                    .italic()
                    .foregroundStyle(.primary.opacity(0.92))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .animation(nil, value: revealedCount)
                }
                .padding(22)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.neonCyan.opacity(isWriting ? 0.65 : 0.40),
                                    Color.neonViolet.opacity(isWriting ? 0.40 : 0.25)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.neonCyan.opacity(isWriting ? 0.22 : 0.10), radius: isWriting ? 26 : 20, y: 4)
                .overlay(alignment: .topTrailing) {
                    if !isWriting {
                        heartButton.padding(14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(cardAppeared ? 1 : 0.92)
                .opacity(cardAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.05), value: cardAppeared)
                .animation(.easeInOut(duration: 0.35), value: isWriting)
                .padding(.horizontal, 24)

                // ── Action row ───────────────────────────────────────────
                if !isWriting {
                    HStack(spacing: 24) {
                        // Copy — free for everyone
                        GlassCircleButton(
                            icon: copied ? "checkmark" : "doc.on.doc",
                            tint: copied ? .green : Color.neonCyan,
                            isActive: copied
                        ) {
                            UIPasteboard.general.string = fullText
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copied = false }
                            }
                        }

                        // Create Card — Pro feature
                        ZStack(alignment: .topTrailing) {
                            GlassCircleButton(icon: "wand.and.stars", tint: Color(hex: 0xc084fc)) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                if pro.isPro {
                                    showCardEditor = true
                                } else {
                                    paywallContext = .cardMode
                                    showPaywall = true
                                }
                            }
                            if !pro.isPro {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: 0xfbbf24))
                                    .padding(5)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.top, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // ── Bottom actions ───────────────────────────────────────
                if !isWriting {
                    VStack(spacing: 14) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            quota.refresh()
                            if pro.isPro || quota.canGenerate {
                                coordinator.path.removeLast()
                                coordinator.generatedWish = nil
                                coordinator.goNext(.generating)
                            } else {
                                paywallContext = .dailyLimit
                                showPaywall = true
                            }
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
                    .transition(.opacity)
                }
            }
        }
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            haptic.prepare()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { cardAppeared = true }
            }
        }
        .task { await runReveal() }
        .onReceive(blinkTimer) { _ in
            caretVisible = isWriting ? !caretVisible : true
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView(context: paywallContext)
        }
        .fullScreenCover(isPresented: $showCardEditor) {
            CardEditorView(
                wishText: fullText,
                occasion: coordinator.occasion?.rawValue ?? "",
                recipientName: coordinator.recipientNameForDisplay
            )
        }
    }

    // MARK: - Live writing reveal

    @MainActor
    private func runReveal() async {
        var lastHapticAt = 0

        while !Task.isCancelled {
            let text = coordinator.generatedWish ?? ""
            let target = text.count

            if revealedCount < target {
                let pending = target - revealedCount

                // Adaptive step — when a lot is buffered (network got ahead),
                // reveal several chars per tick so we stay smooth and never lag.
                let step = pending > 140 ? 4 : pending > 60 ? 2 : 1
                revealedCount = min(target, revealedCount + step)

                // Subtle typewriter haptic, throttled
                if revealedCount - lastHapticAt >= 16 {
                    lastHapticAt = revealedCount
                    haptic.selectionChanged()
                }

                // Cadence: race to catch up if far behind, otherwise type with
                // a natural rhythm that lingers on punctuation.
                let delay: UInt64
                if pending > 60 {
                    delay = 7_000_000        // ~7ms — fast, smooth catch-up
                } else {
                    let lastIdx = text.index(text.startIndex, offsetBy: revealedCount - 1)
                    let ch = text[lastIdx]
                    if ".!?".contains(ch)        { delay = 200_000_000 }  // end of sentence
                    else if ",;:—".contains(ch)  { delay = 80_000_000 }   // clause pause
                    else if ch == " "            { delay = 26_000_000 }   // between words
                    else                         { delay = 17_000_000 }   // letters
                }
                try? await Task.sleep(nanoseconds: delay)

            } else if coordinator.isGenerating {
                // Caught up to the buffer but more tokens are still coming.
                try? await Task.sleep(nanoseconds: 25_000_000)
            } else {
                break   // stream finished and fully revealed
            }
        }

        // Snap to the final text in case of cancellation/rounding.
        revealedCount = (coordinator.generatedWish ?? "").count
        if !fullText.isEmpty {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Heart button

    private var heartButton: some View {
        Button {
            store.toggle(
                text: fullText,
                occasion: coordinator.occasion ?? .birthday,
                tone: coordinator.tone,
                length: coordinator.length,
                recipientName: coordinator.recipientNameForDisplay
            )
            if store.isFavorite(text: fullText) {
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
}
