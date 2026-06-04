import SwiftUI
import UIKit

// MARK: - AddPeopleBanner
// Cross-promotion from Favorites → People. Shown only when the user has no
// people saved yet (controlled by the parent).

struct AddPeopleBanner: View {
    var onTap:   () -> Void
    var onClose: () -> Void

    private let accent = Color(hex: 0xc084fc)

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text("Never forget a birthday")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Get reminders for the people you love")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            // Add pill
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap()
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.12))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(accent.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.4))
                    .frame(width: 22, height: 22)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture { onTap() }
    }
}
