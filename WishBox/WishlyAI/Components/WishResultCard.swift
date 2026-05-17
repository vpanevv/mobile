import SwiftUI
import UIKit

struct WishResultCard: View {
    let wish: String
    let occasion: HolidayType
    let tone: WishTone
    let length: WishLength
    let recipientName: String?
    let onRegenerate: () -> Void

    @EnvironmentObject var store: FavoritesStore
    @State private var displayedText = ""
    @State private var isTyping = false
    @State private var copied = false
    @State private var typewriterTask: Task<Void, Never>?
    @State private var heartBurst = false
    @State private var heartScale: CGFloat = 1.0
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            // ── Main card ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 20) {

                // Badge row
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
                        ProgressView()
                            .tint(Color.neonCyan)
                            .scaleEffect(0.6)
                    }
                }

                // Wish text — typewriter
                Text(displayedText + (isTyping ? "▋" : ""))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.primary.opacity(0.92))
                    .lineSpacing(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(nil, value: displayedText)

                // Copy button — shown after typing
                if !isTyping {
                    Button {
                        UIPasteboard.general.string = wish
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            copied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                copied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))
                            Text(copied ? "Copied!" : "Copy Wish")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(copied ? .green : Color.neonCyan)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(copied ? Color.green.opacity(0.08) : Color.neonCyan.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            copied ? Color.green.opacity(0.35) : Color.neonCyan.opacity(0.35),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: copied ? Color.green.opacity(0.12) : Color.neonCyan.opacity(0.12), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(22)
            .background(
                scheme == .dark
                    ? Color.surface.opacity(0.94)
                    : Color(UIColor.systemBackground).opacity(0.94)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.neonCyan.opacity(0.45),
                                Color.neonViolet.opacity(0.30),
                                Color.neonCyan.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.neonCyan.opacity(0.12), radius: 24, x: 0, y: 4)
            .overlay(alignment: .topTrailing) {
                heartButton
                    .padding(14)
            }

            // ── Regenerate ───────────────────────────────────────────────
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onRegenerate()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                    Text("Generate another")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.primary.opacity(0.35))
                .padding(.top, 14)
            }
            .buttonStyle(.plain)
        }
        .onAppear { startTypewriter() }
    }

    private var heartButton: some View {
        let isFav = store.isFavorite(text: wish)
        return Button {
            store.toggle(text: wish, occasion: occasion, tone: tone, length: length, recipientName: recipientName)
            heartBurst = true
            if store.isFavorite(text: wish) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { heartScale = 1.4 }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6).delay(0.15)) { heartScale = 0.9 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7).delay(0.35)) { heartScale = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { heartBurst = false }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .frame(width: 38, height: 38)
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isFav ? Color(hex: 0xf43f5e) : Color.white.opacity(0.7))
                    .scaleEffect(heartScale)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFav ? "Remove from favorites" : "Add to favorites")
        .overlay { if heartBurst { HeartBurstView() } }
    }

    private func startTypewriter() {
        typewriterTask?.cancel()
        displayedText = ""
        isTyping = true
        typewriterTask = Task {
            for char in wish {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: 22_000_000)
                guard !Task.isCancelled else { break }
                displayedText.append(char)
            }
            isTyping = false
        }
    }
}
