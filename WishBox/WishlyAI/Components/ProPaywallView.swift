import SwiftUI
import StoreKit
import UIKit

// MARK: - PaywallContext

enum PaywallContext {
    case general      // generic upsell
    case cardMode     // user tapped Create Card without Pro
    case dailyLimit   // free user exhausted today's 3 wishes
}

// MARK: - ProPaywallView

struct ProPaywallView: View {
    var context: PaywallContext = .general

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = ProStore.shared
    @AppStorage("wishlyai.isDark") private var isDark: Bool = true

    @State private var purchasingID: String? = nil
    @State private var errorMessage: String? = nil

    private let accent = Color(hex: 0xc084fc)

    var body: some View {
        ZStack {
            NeuralBackground().ignoresSafeArea()
            FlowAmbientLayer()

            VStack(spacing: 0) {
                // ── Top bar ─────────────────────────────────────────────
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.7))
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        Task {
                            await store.restore()
                            if store.isPro { dismiss() }
                        }
                    } label: {
                        Text("Restore")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ── Crown orb ────────────────────────────────────
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [accent.opacity(0.35), .clear],
                                        center: .center, startRadius: 0, endRadius: 70
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .blur(radius: 12)

                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle().stroke(
                                        LinearGradient(
                                            colors: [Color(hex: 0xfbbf24).opacity(0.6), accent.opacity(0.4)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.4
                                    )
                                )
                                .frame(width: 86, height: 86)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: 0xfbbf24), Color(hex: 0xf59e0b)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        }
                        .padding(.top, 6)

                        Text("WishlyAI Pro")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.top, 14)

                        Text(headline)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 36)

                        // ── Features ─────────────────────────────────────
                        VStack(spacing: 12) {
                            featureRow(icon: "infinity",          tint: Color.neonCyan,
                                       title: "Unlimited wishes", sub: "No daily limit — generate freely")
                            featureRow(icon: "wand.and.stars",    tint: accent,
                                       title: "Wish cards",       sub: "Design & share beautiful cards")
                            featureRow(icon: "paintpalette.fill", tint: Color(hex: 0xf43f5e),
                                       title: "All card styles",  sub: "Every background and font")
                            featureRow(icon: "heart.fill",        tint: Color(hex: 0xfb7185),
                                       title: "Support WishlyAI", sub: "Help us craft more magic")
                        }
                        .padding(.top, 26)
                        .padding(.horizontal, 26)

                        // ── Products ─────────────────────────────────────
                        VStack(spacing: 12) {
                            if store.isPro {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.green)
                                    Text("You're Pro — everything is unlocked!")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            } else if store.products.isEmpty {
                                VStack(spacing: 10) {
                                    if store.isLoadingProducts {
                                        ProgressView().tint(accent)
                                    } else {
                                        Text("Couldn't reach the App Store.")
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundStyle(.secondary)
                                        Button("Try again") {
                                            Task { await store.loadProducts() }
                                        }
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(accent)
                                    }
                                }
                                .frame(height: 80)
                            } else {
                                ForEach(store.products, id: \.id) { product in
                                    productButton(product)
                                }
                            }
                        }
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.top, 12)
                                .padding(.horizontal, 24)
                        }

                        Text("Subscriptions auto-renew until cancelled.\nManage anytime in Settings.")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.top, 18)
                            .padding(.bottom, 36)
                    }
                }
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .presentationDetents([.large])
        .presentationCornerRadius(32)
        .task { await store.loadProducts() }
    }

    // MARK: - Pieces

    private var headline: String {
        switch context {
        case .cardMode:   return "Wish cards are a Pro feature.\nUnlock beautiful, shareable designs."
        case .dailyLimit: return "You've used your \(WishQuota.dailyLimit) free wishes for today.\nGo unlimited with Pro — or come back tomorrow."
        case .general:    return "Unlimited wishes and beautiful,\nshareable wish cards."
        }
    }

    private func featureRow(icon: String, tint: Color, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(sub)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func productButton(_ product: Product) -> some View {
        let isSubscription = product.type == .autoRenewable
        let isBusy = purchasingID == product.id

        return Button {
            buy(product)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(isSubscription ? "\(product.displayPrice) / month" : "\(product.displayPrice) once — yours forever")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .opacity(0.85)
                }
                Spacer()
                if isBusy {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 62)
            .background(
                Group {
                    if isSubscription {
                        LinearGradient(
                            colors: [Color(hex: 0x22d3ee), Color(hex: 0x9333ea), Color(hex: 0xc084fc)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(hex: 0x9333ea).opacity(0.55), Color(hex: 0xc084fc).opacity(0.55)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: accent.opacity(isSubscription ? 0.35 : 0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(purchasingID != nil)
    }

    private func buy(_ product: Product) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasingID = product.id
        errorMessage = nil
        Task {
            do {
                let success = try await store.purchase(product)
                purchasingID = nil
                if success {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                purchasingID = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}
