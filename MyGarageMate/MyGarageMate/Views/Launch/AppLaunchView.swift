import SwiftUI

struct AppLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingContent = false

    var body: some View {
        ZStack {
            AuthGateView()
                .opacity(isShowingContent ? 1 : 0)
                .scaleEffect(isShowingContent ? 1 : 1.02)
                .allowsHitTesting(isShowingContent)

            if !isShowingContent {
                MyGarageMateLaunchSplash()
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
            }
        }
        .task {
            let delay: UInt64 = reduceMotion ? 650_000_000 : 1_650_000_000
            try? await Task.sleep(nanoseconds: delay)
            withAnimation(.smooth(duration: reduceMotion ? 0.22 : 0.55)) {
                isShowingContent = true
            }
        }
    }
}

private struct MyGarageMateLaunchSplash: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            LaunchBackgroundEffect(animate: animate && !reduceMotion)

            VStack(spacing: 22) {
                iconEffect

                VStack(spacing: 6) {
                    Text("MyGarageMate")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Your garage, beautifully organized")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 10)
                .animation(.smooth(duration: 0.55).delay(0.18), value: animate)
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.smooth(duration: 0.7)) {
                animate = true
            }
        }
        .accessibilityLabel("MyGarageMate is opening")
    }

    private var iconEffect: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
                    .frame(width: 154 + CGFloat(index * 28), height: 154 + CGFloat(index * 28))
                    .scaleEffect(animate ? 1.08 + CGFloat(index) * 0.04 : 0.82)
                    .opacity(animate ? 0.06 : 0.34)
                    .blur(radius: CGFloat(index) * 1.2)
                    .animation(
                        reduceMotion ? .default : .easeOut(duration: 1.65).repeatForever(autoreverses: false).delay(Double(index) * 0.22),
                        value: animate
                    )
            }

            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: 174, height: 174)
                .overlay {
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: .cyan.opacity(0.28), radius: animate ? 34 : 12, y: 18)

            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 31, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 31, style: .continuous)
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                }
                .overlay {
                    LaunchIconShine(animate: animate && !reduceMotion)
                        .clipShape(RoundedRectangle(cornerRadius: 31, style: .continuous))
                }
                .scaleEffect(animate ? 1 : 0.86)
                .rotation3DEffect(.degrees(animate ? 0 : -7), axis: (x: 1, y: -0.35, z: 0))
                .shadow(color: .black.opacity(0.45), radius: 20, y: 16)
                .accessibilityHidden(true)
        }
        .frame(width: 228, height: 228)
    }
}

private struct LaunchBackgroundEffect: View {
    let animate: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.02, green: 0.04, blue: 0.07),
                            Color(red: 0.03, green: 0.11, blue: 0.16),
                            Color(red: 0.00, green: 0.02, blue: 0.05)
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )

                drawOrb(
                    in: &context,
                    size: size,
                    center: CGPoint(
                        x: size.width * (animate ? 0.30 + 0.05 * sin(time * 0.7) : 0.30),
                        y: size.height * (animate ? 0.24 + 0.04 * cos(time * 0.55) : 0.24)
                    ),
                    radius: min(size.width, size.height) * 0.46,
                    colors: [.cyan.opacity(0.34), .blue.opacity(0.08), .clear]
                )

                drawOrb(
                    in: &context,
                    size: size,
                    center: CGPoint(
                        x: size.width * (animate ? 0.78 + 0.04 * cos(time * 0.45) : 0.78),
                        y: size.height * (animate ? 0.70 + 0.05 * sin(time * 0.62) : 0.70)
                    ),
                    radius: min(size.width, size.height) * 0.42,
                    colors: [.teal.opacity(0.26), .green.opacity(0.08), .clear]
                )

                drawOrb(
                    in: &context,
                    size: size,
                    center: CGPoint(x: size.width * 0.52, y: size.height * 0.48),
                    radius: min(size.width, size.height) * 0.38,
                    colors: [.white.opacity(0.08), .cyan.opacity(0.04), .clear]
                )
            }
            .overlay {
                LinearGradient(
                    colors: [.white.opacity(0.12), .clear, .black.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.softLight)
            }
            .overlay {
                RadialGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    center: .center,
                    startRadius: 120,
                    endRadius: 560
                )
            }
        }
    }

    private func drawOrb(
        in context: inout GraphicsContext,
        size: CGSize,
        center: CGPoint,
        radius: CGFloat,
        colors: [Color]
    ) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.addFilter(.blur(radius: 28))
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(Gradient(colors: colors), center: center, startRadius: 0, endRadius: radius)
        )
    }
}

private struct LaunchIconShine: View {
    let animate: Bool

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.62), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: proxy.size.width * 0.30, height: proxy.size.height * 1.55)
                .rotationEffect(.degrees(28))
                .offset(x: animate ? proxy.size.width * 1.25 : -proxy.size.width * 0.72)
                .animation(.easeInOut(duration: 1.25).delay(0.22), value: animate)
                .blendMode(.screen)
        }
        .allowsHitTesting(false)
    }
}
