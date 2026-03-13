import SwiftUI

struct HomeIntroView: View {
    let onContinue: () -> Void

    @State private var logoIsVisible = false
    @State private var contentIsVisible = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            IntroBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 32)

                VStack(spacing: 28) {
                    AILogoMark(isAnimating: pulse)
                        .scaleEffect(logoIsVisible ? 1 : 0.72)
                        .opacity(logoIsVisible ? 1 : 0)
                        .rotationEffect(.degrees(logoIsVisible ? 0 : -12))

                    VStack(spacing: 12) {
                        Text("TODO AI")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(.white)

                        Text("Plan smarter. Achieve more.")
                            .font(.headline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .offset(y: contentIsVisible ? 0 : 26)
                    .opacity(contentIsVisible ? 1 : 0)

                    Button(action: onContinue) {
                        HStack(spacing: 12) {
                            Text("START YOUR DAY")
                                .font(.headline.weight(.black))
                                .tracking(1.4)

                            Image(systemName: "arrow.right")
                                .font(.headline.weight(.black))
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.67, green: 0.98, blue: 0.96),
                                    Color(red: 0.42, green: 0.95, blue: 0.99),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.65), lineWidth: 1.2)
                        }
                        .shadow(color: Color.cyan.opacity(0.42), radius: 22, y: 12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 28)
                    .offset(y: contentIsVisible ? 0 : 30)
                    .opacity(contentIsVisible ? 1 : 0)

                    Text("Your AI-powered daily buddy")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .opacity(contentIsVisible ? 1 : 0)
                }

                Spacer()

                Text("v1.0")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.92),
                                Color.cyan.opacity(0.95),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.cyan.opacity(0.35), radius: 18, y: 6)
                    .padding(.bottom, 10)
                    .opacity(contentIsVisible ? 1 : 0)
            }
            .padding(.vertical, 44)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) {
                logoIsVisible = true
            }

            withAnimation(.spring(response: 0.82, dampingFraction: 0.84).delay(0.16)) {
                contentIsVisible = true
            }

            pulse = true
        }
    }
}

private struct IntroBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.01, green: 0.02, blue: 0.08),
                        Color(red: 0.04, green: 0.10, blue: 0.22),
                        Color(red: 0.03, green: 0.23, blue: 0.30),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.38, green: 0.97, blue: 0.95).opacity(0.28),
                        .clear,
                    ],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 280
                )
                .offset(x: -20, y: -80)

                RadialGradient(
                    colors: [
                        Color(red: 0.32, green: 0.49, blue: 1.00).opacity(0.30),
                        .clear,
                    ],
                    center: .bottomLeading,
                    startRadius: 20,
                    endRadius: 300
                )
                .offset(x: 10, y: 120)

                movingOrb(
                    color: Color.cyan.opacity(0.22),
                    size: 320,
                    x: -110 + cos(time * 0.23) * 24,
                    y: -240 + sin(time * 0.16) * 30
                )

                movingOrb(
                    color: Color.blue.opacity(0.18),
                    size: 260,
                    x: 140 + sin(time * 0.19) * 28,
                    y: -40 + cos(time * 0.21) * 34
                )

                movingOrb(
                    color: Color.white.opacity(0.08),
                    size: 280,
                    x: -40 + cos(time * 0.12) * 40,
                    y: 290 + sin(time * 0.18) * 22
                )

                CircuitGrid(time: time)
            }
            .ignoresSafeArea()
        }
    }

    private func movingOrb(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 34)
            .offset(x: x, y: y)
    }
}

private struct CircuitGrid: View {
    let time: TimeInterval

    var body: some View {
        ZStack {
            Path { path in
                let width: CGFloat = 420
                let height: CGFloat = 860
                let spacing: CGFloat = 54

                stride(from: 0 as CGFloat, through: width, by: spacing).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }

                stride(from: 0 as CGFloat, through: height, by: spacing).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.05), lineWidth: 1)
            .frame(width: 420, height: 860)
            .rotationEffect(.degrees(-12))
            .offset(y: 30)

            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? Color.cyan.opacity(0.48) : Color.white.opacity(0.32))
                    .frame(width: index.isMultiple(of: 2) ? 8 : 5, height: index.isMultiple(of: 2) ? 8 : 5)
                    .blur(radius: index.isMultiple(of: 2) ? 0.2 : 0.8)
                    .offset(
                        x: CGFloat(-160 + (index * 48)),
                        y: CGFloat(-220 + ((index % 4) * 138)) + sin(time * 0.45 + Double(index)) * 16
                    )
            }
        }
    }
}

private struct AILogoMark: View {
    let isAnimating: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.24),
                            Color.cyan.opacity(0.14),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 124
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(isAnimating ? 1.06 : 0.95)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 208, height: 208)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: isAnimating)

            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.cyan.opacity(0.1),
                            Color.white.opacity(0.95),
                            Color.cyan.opacity(0.8),
                            Color.white.opacity(0.1),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 176, height: 176)
                .rotationEffect(.degrees(isAnimating ? -360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)

            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.13, blue: 0.24),
                            Color(red: 0.05, green: 0.08, blue: 0.16),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 148, height: 148)
                .overlay {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
                }
                .shadow(color: Color.cyan.opacity(0.24), radius: 24, y: 14)

            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    chipNode

                    VStack(alignment: .leading, spacing: 8) {
                        taskRow(width: 54, isCompleted: true)
                        taskRow(width: 40, isCompleted: true)
                    }
                }

                HStack(spacing: 12) {
                    taskRow(width: 64, isCompleted: false)

                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.cyan)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            ForEach(0..<4, id: \.self) { index in
                connectionDot(angle: Double(index) * 90, active: index.isMultiple(of: 2))
            }
        }
        .frame(width: 280, height: 280)
    }

    private var chipNode: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.95),
                            Color(red: 0.31, green: 0.59, blue: 1.00),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)

            Image(systemName: "brain.head.profile")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color.black.opacity(0.84))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
    }

    private func taskRow(width: CGFloat, isCompleted: Bool) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isCompleted ? Color.cyan.opacity(0.95) : Color.white.opacity(0.14))
                    .frame(width: 24, height: 24)

                Image(systemName: isCompleted ? "checkmark" : "circle")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isCompleted ? Color.black.opacity(0.82) : .white.opacity(0.72))
            }

            Capsule()
                .fill(isCompleted ? Color.white.opacity(0.72) : Color.white.opacity(0.22))
                .frame(width: width, height: 8)
        }
    }

    private func connectionDot(angle: Double, active: Bool) -> some View {
        let radians = angle * .pi / 180

        return Circle()
            .fill(active ? Color.cyan.opacity(0.92) : Color.white.opacity(0.55))
            .frame(width: active ? 12 : 8, height: active ? 12 : 8)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
            .offset(
                x: cos(radians) * 108,
                y: sin(radians) * 108
            )
    }
}
