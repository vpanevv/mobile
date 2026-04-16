import SwiftUI
import UIKit

struct GenerateButton: View {
    let isLoading: Bool
    let action: () -> Void

    @State private var dotCount = 0
    @State private var dotTimer: Timer?

    private var dots: String { String(repeating: ".", count: dotCount) }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(isLoading ? "Generating\(dots)" : "Generate Wish")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: isLoading
                        ? [Color.neonCyan.opacity(0.35), Color.neonViolet.opacity(0.35)]
                        : [Color.neonCyan, Color(hex: 0x7c3aed)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .shadow(color: Color.neonCyan.opacity(0.30), radius: 14, x: 0, y: 0)
        .onChange(of: isLoading) { _, loading in
            if loading {
                dotCount = 0
                dotTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                    dotCount = (dotCount + 1) % 4
                }
            } else {
                dotTimer?.invalidate()
                dotTimer = nil
            }
        }
    }
}
