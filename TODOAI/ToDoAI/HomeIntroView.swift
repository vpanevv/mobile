import SwiftUI

struct HomeIntroView: View {
    let onContinue: () -> Void

    @State private var logoIsVisible = false
    @State private var contentIsVisible = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            IntroBackground()

            VStack(spacing: 28) {
                Spacer()

                AILogoMark(isAnimating: pulse)
                    .scaleEffect(logoIsVisible ? 1 : 0.72)
                    .opacity(logoIsVisible ? 1 : 0)
                    .rotationEffect(.degrees(logoIsVisible ? 0 : -12))

                VStack(spacing: 12) {
                    Text("TODO AI")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.white)

                    Text("Sharper focus. Smarter momentum. A cleaner start to the day.")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .offset(y: contentIsVisible ? 0 : 26)
                .opacity(contentIsVisible ? 1 : 0)

                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        Text("LET'S GO")
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

                Text("Your AI-powered daily planner")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .padding(.top, 6)
                    .opacity(contentIsVisible ? 1 : 0)

                Spacer()
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
                            Color.white.opacity(0.34),
                            Color.cyan.opacity(0.08),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(isAnimating ? 1.05 : 0.94)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.88),
                            Color(red: 0.76, green: 0.99, blue: 0.96),
                            Color(red: 0.58, green: 0.86, blue: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 126, height: 126)
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1.2)
                }
                .shadow(color: Color.cyan.opacity(0.3), radius: 22, y: 14)
                .rotationEffect(.degrees(isAnimating ? 8 : -8))
                .animation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true), value: isAnimating)

            Image(systemName: "brain.head.profile")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(Color.black.opacity(0.8))

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == 1 ? Color.white : Color.cyan)
                    .frame(width: 10, height: 10)
                    .offset(x: index == 0 ? -66 : (index == 1 ? 0 : 66), y: 0)

                Capsule()
                    .fill(Color.white.opacity(0.72))
                    .frame(width: 54, height: 2)
                    .offset(x: index == 0 ? -33 : 33, y: 0)
                    .opacity(index == 1 ? 0 : 1)
            }

            ForEach(0..<6, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "circle.fill")
                    .font(.system(size: index.isMultiple(of: 2) ? 16 : 6, weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 2) ? Color.white.opacity(0.78) : Color.cyan.opacity(0.72))
                    .offset(
                        x: CGFloat(cos(Double(index) * .pi / 3) * 92),
                        y: CGFloat(sin(Double(index) * .pi / 3) * 92)
                    )
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 16).repeatForever(autoreverses: false), value: isAnimating)
            }
        }
        .frame(width: 240, height: 240)
    }
}
