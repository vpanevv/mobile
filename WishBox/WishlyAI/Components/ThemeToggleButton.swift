import SwiftUI
import UIKit

struct ThemeToggleButton: View {
    @Binding var isDark: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isDark.toggle()
            }
        } label: {
            Image(systemName: isDark ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.neonCyan)
                .frame(width: 38, height: 38)
                .background(
                    isDark
                        ? Color.surface.opacity(0.9)
                        : Color(UIColor.systemBackground).opacity(0.9)
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.neonCyan.opacity(0.30), lineWidth: 1))
                .shadow(color: Color.neonCyan.opacity(0.12), radius: 8)
        }
        .buttonStyle(.plain)
    }
}
