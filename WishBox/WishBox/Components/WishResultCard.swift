import SwiftUI
import UIKit

struct WishResultCard: View {
    let wish: String
    let onRegenerate: () -> Void

    @State private var displayedText = ""
    @State private var isTyping = false
    @State private var copied = false
    @State private var typewriterTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // ── Main card ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 20) {

                // "AI Generated" badge
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

                // Wish text — typewriter reveal
                Text(displayedText + (isTyping ? "▋" : ""))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(nil, value: displayedText)

                // Copy button — appears after typing finishes
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
                                .fill(
                                    copied
                                        ? Color.green.opacity(0.08)
                                        : Color.neonCyan.opacity(0.08)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            copied
                                                ? Color.green.opacity(0.35)
                                                : Color.neonCyan.opacity(0.35),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(
                            color: copied ? Color.green.opacity(0.15) : Color.neonCyan.opacity(0.15),
                            radius: 8
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(22)
            .background(Color.surface.opacity(0.94))
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
                .foregroundStyle(.white.opacity(0.35))
                .padding(.top, 14)
            }
            .buttonStyle(.plain)
        }
        .onAppear { startTypewriter() }
    }

    private func startTypewriter() {
        typewriterTask?.cancel()
        displayedText = ""
        isTyping = true
        typewriterTask = Task {
            for char in wish {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: 22_000_000) // ~22 ms / char
                guard !Task.isCancelled else { break }
                displayedText.append(char)
            }
            isTyping = false
        }
    }
}
