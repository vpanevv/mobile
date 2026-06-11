import SwiftUI
import UIKit

// MARK: - ResultStepView
// The wish streams in LIVE — coordinator.generatedWish grows token-by-token
// while coordinator.isGenerating is true. No fake typewriter.

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

    private var wish: String { coordinator.generatedWish ?? "" }
    private var isStreaming: Bool { coordinator.isGenerating }
    private var isFav: Bool { store.isFavorite(text: wish) }

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
                Text("Here's your wish 🎁")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .opacity(cardAppeared ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: cardAppeared)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 24)

                // ── Wish card ────────────────────────────────────────────
                VStack(spacing: 18) {
                    // Badge — centered
                    HStack(spacing: 7) {
                        Circle()
                            .fill(isStreaming ? Color.neonCyan : Color.neonCyan.opacity(0.6))
                            .frame(width: 7, height: 7)
                            .shadow(color: isStreaming ? Color.neonCyan.opacity(0.8) : .clear, radius: 4)
                        Text(isStreaming ? "GENERATING" : "AI GENERATED")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.neonCyan.opacity(0.85))
                            .tracking(2.5)
                        if isStreaming {
                            ProgressView().tint(Color.neonCyan).scaleEffect(0.55)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Live-streaming wish text — hugs its own height
                    Text(wish + (isStreaming ? "▋" : ""))
                        .font(.system(size: 19, weight: .regular, design: .rounded))
                        .italic()
                        .foregroundStyle(.primary.opacity(0.92))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
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
                    if !isStreaming {
                        heartButton.padding(14)
                    }
                }
                .scaleEffect(cardAppeared ? 1 : 0.92)
                .opacity(cardAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.05), value: cardAppeared)
                .padding(.horizontal, 24)

                // ── Action row ───────────────────────────────────────────
                if !isStreaming {
                    HStack(spacing: 24) {
                        // Copy — free for everyone
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
                    .opacity(cardAppeared ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.25), value: cardAppeared)
                }

                Spacer()

                // ── Bottom actions ───────────────────────────────────────
                if !isStreaming {
                    VStack(spacing: 14) {
                        // Regenerate (counts against the free daily quota)
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
                }
            }
        }
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { cardAppeared = true }
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView(context: paywallContext)
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
}
