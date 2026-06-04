import SwiftUI
import UIKit

// MARK: - FlowAmbientLayer
// Drifting glow-blob layer drawn in a Canvas, driven by a TimelineView clock.
// Time-based motion (not SwiftUI implicit animation) means it runs at a
// CONSTANT speed everywhere and is completely immune to sibling `withAnimation`
// transactions (typewriter, loaders, etc.). Radial-gradient fills are far
// cheaper than full-screen Gaussian blur, so it stays buttery smooth.

struct FlowAmbientLayer: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Light mode: dimmed to tinted washes; dark mode: full-strength
    private var alpha: Double { scheme == .dark ? 1.0 : 0.5 }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            if reduceMotion {
                canvas(t: 0)
                    .frame(width: size.width, height: size.height)
            } else {
                TimelineView(.animation) { timeline in
                    canvas(t: timeline.date.timeIntervalSinceReferenceDate)
                        .frame(width: size.width, height: size.height)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func canvas(t: TimeInterval) -> some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let maxR = max(w, h)

            // slow sinusoidal drift — low frequencies = smooth, lazy motion
            func osc(_ freq: Double, _ phase: Double) -> CGFloat {
                CGFloat(sin(t * 2 * .pi * freq + phase))
            }

            func blob(cx: CGFloat, cy: CGFloat, r: CGFloat, hex: UInt, a: Double) {
                let center = CGPoint(x: cx, y: cy)
                let rect   = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                ctx.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(hex: hex).opacity(a * alpha),
                            Color(hex: hex).opacity(0)
                        ]),
                        center: center, startRadius: 0, endRadius: r
                    )
                )
            }

            // Top-left violet
            blob(cx: w * 0.22 + osc(0.020, 0.0) * w * 0.05,
                 cy: h * 0.18 + osc(0.016, 1.0) * h * 0.05,
                 r: maxR * 0.55, hex: 0x6b21a8, a: 0.50)

            // Bottom-right pink
            blob(cx: w * 0.80 + osc(0.018, 2.0) * w * 0.05,
                 cy: h * 0.74 + osc(0.022, 0.5) * h * 0.05,
                 r: maxR * 0.50, hex: 0xbe185d, a: 0.42)

            // Centre cyan shimmer
            blob(cx: w * 0.50 + osc(0.024, 3.0) * w * 0.06,
                 cy: h * 0.46 + osc(0.015, 2.0) * h * 0.04,
                 r: maxR * 0.42, hex: 0x0e7490, a: 0.28)
        }
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
