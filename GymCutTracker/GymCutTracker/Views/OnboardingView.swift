import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var selection = 0

    private let pages: [OnboardingPage] = [
        .init(
            title: "Your cut, tracked like training",
            subtitle: "Monday, Wednesday, and Friday are ready with the program from your screenshots.",
            symbol: "figure.strengthtraining.traditional.circle.fill",
            accent: Color(red: 0.31, green: 1.0, blue: 0.42)
        ),
        .init(
            title: "Log every working set",
            subtitle: "Track weight, reps, RPE, notes, and completed sets without turning the session into admin.",
            symbol: "chart.line.uptrend.xyaxis.circle.fill",
            accent: Color(red: 0.15, green: 0.58, blue: 1.0)
        ),
        .init(
            title: "Hold strength while cutting",
            subtitle: "See exercise history, body weight, and next-session recommendations in one premium notebook.",
            symbol: "slider.horizontal.3",
            accent: Color(red: 0.31, green: 1.0, blue: 0.42)
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.025, blue: 0.03),
                    Color(red: 0.04, green: 0.07, blue: 0.06),
                    Color(red: 0.02, green: 0.04, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                header

                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageCard(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
    }

    private var header: some View {
        HStack {
            Text("Gym Cut Tracker")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Button("Skip") {
                onFinish()
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.78))
        }
    }

    private func pageCard(_ page: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.18))
                    .frame(width: 170, height: 170)

                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 210, height: 210)

                Image(systemName: page.symbol)
                    .font(.system(size: 76, weight: .medium))
                    .foregroundStyle(.white, page.accent)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                Text(page.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(page.subtitle)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var footer: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == selection ? .white : .white.opacity(0.24))
                        .frame(width: index == selection ? 28 : 8, height: 8)
                }
            }

            Button {
                if selection == pages.count - 1 {
                    onFinish()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        selection += 1
                    }
                }
            } label: {
                Text(selection == pages.count - 1 ? "Start Training" : "Continue")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(red: 0.31, green: 1.0, blue: 0.42), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
}

#Preview {
    OnboardingView(onFinish: {})
}
