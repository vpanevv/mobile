import SwiftUI
import UIKit

// MARK: - FlowProgressBar

struct FlowProgressBar: View {
    let currentStep: WishFlowCoordinator.Step
    private let total = 6

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                let isActive = index == currentStep.progressIndex
                Capsule()
                    .fill(isActive ? Color.white : Color.white.opacity(0.28))
                    .frame(width: isActive ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.38, dampingFraction: 0.75), value: currentStep.progressIndex)
            }
        }
    }
}

// MARK: - PrimaryFlowButton

struct PrimaryFlowButton: View {
    let label: String
    var icon: String = "chevron.right"
    var disabled: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            guard !disabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.18, dampingFraction: 0.65)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { pressed = false }
            }
            action()
        } label: {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 29, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .stroke(Color.white.opacity(disabled ? 0.05 : 0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.38 : 1.0)
        .scaleEffect(pressed ? 0.96 : 1.0)
        .disabled(disabled)
        .padding(.horizontal, 32)
    }
}

// MARK: - SkipButton

struct SkipButton: View {
    let label: String
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowGlassBackButton

struct FlowGlassBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var overrideAction: (() -> Void)? = nil

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if let action = overrideAction {
                action()
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.8))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowStepTitle

struct FlowStepTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - GlassCircleButton (for result actions)

struct GlassCircleButton: View {
    let icon: String
    let tint: Color
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isActive ? tint : Color.white.opacity(0.8))
                .frame(width: 56, height: 56)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(isActive ? tint.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: isActive ? tint.opacity(0.3) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}
