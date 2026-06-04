import SwiftUI
import UIKit

// MARK: - FlowAmbientLayer
// Self-contained drifting blob layer. Add inside any screen's ZStack.
// No external dependencies — autonomous drift animations work in both modes.

struct FlowAmbientLayer: View {
    @Environment(\.colorScheme) private var scheme
    @State private var d1 = false
    @State private var d2 = false
    @State private var d3 = false

    // Light mode: dimmed to tinted washes; dark mode: full-strength
    private var alpha: Double { scheme == .dark ? 1.0 : 0.48 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Top-left violet
                Ellipse()
                    .fill(Color(hex: 0x6b21a8).opacity(0.50 * alpha))
                    .frame(width: 320, height: 230)
                    .blur(radius: 72)
                    .offset(x: -w * 0.26, y: d1 ? -h * 0.22 : -h * 0.30)
                    .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: d1)

                // Bottom-right pink
                Ellipse()
                    .fill(Color(hex: 0xbe185d).opacity(0.42 * alpha))
                    .frame(width: 290, height: 210)
                    .blur(radius: 76)
                    .offset(x: w * 0.26, y: d2 ? h * 0.26 : h * 0.20)
                    .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: d2)

                // Centre cyan shimmer
                Ellipse()
                    .fill(Color(hex: 0x0e7490).opacity(0.28 * alpha))
                    .frame(width: 240, height: 170)
                    .blur(radius: 62)
                    .offset(x: d3 ? -18 : 18, y: -h * 0.04)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: d3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { d1 = true; d2 = true; d3 = true }
    }
}

// MARK: - FlowProgressBar

struct FlowProgressBar: View {
    let currentStep: WishFlowCoordinator.Step
    private let total = 7

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                let isActive = index == currentStep.progressIndex
                Capsule()
                    .fill(
                        isActive
                            ? (scheme == .dark ? Color.white : Color(hex: 0x9333ea))
                            : (scheme == .dark ? Color.white.opacity(0.28) : Color(hex: 0x9333ea).opacity(0.22))
                    )
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

    @Environment(\.colorScheme) private var scheme
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
            .background(
                Group {
                    if scheme == .dark {
                        // Dark mode: glass pill — visible against dark gradient background
                        AnyView(
                            RoundedRectangle(cornerRadius: 29, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 29, style: .continuous)
                                        .stroke(Color.white.opacity(disabled ? 0.05 : 0.18), lineWidth: 1)
                                )
                        )
                    } else {
                        // Light mode: brand gradient — clearly visible on light backgrounds
                        AnyView(
                            RoundedRectangle(cornerRadius: 29, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0x9333ea), Color(hex: 0xc084fc)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 29, style: .continuous))
            .shadow(
                color: scheme == .dark
                    ? .black.opacity(0.2)
                    : Color(hex: 0x9333ea).opacity(0.35),
                radius: 12, y: 4
            )
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
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.colorScheme)  private var scheme
    var overrideAction: (() -> Void)? = nil

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if let action = overrideAction { action() } else { dismiss() }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(scheme == .dark ? Color.white.opacity(0.9) : Color(hex: 0x6b21a8))
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                )
                .contentShape(Circle())
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
