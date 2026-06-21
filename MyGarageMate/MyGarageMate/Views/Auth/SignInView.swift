import AuthenticationServices
import SwiftData
import SwiftUI

struct SignInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = AuthViewModel()
    @State private var appeared = false

    private let highlights: [(symbol: String, tint: Color, title: String, subtitle: String)] = [
        ("car.2.fill", Theme.accent, "Your whole garage", "Every car, photo, and detail in one place"),
        ("chart.bar.xaxis", Theme.highlight, "See your spend", "Beautiful cost trends and breakdowns"),
        ("bell.badge.fill", Theme.mist, "Never miss service", "Smart reminders for what's coming up"),
        ("lock.fill", Theme.ember, "Private by design", "Everything stays on your device")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                VStack(spacing: Theme.Spacing.xl) {
                    Spacer(minLength: Theme.Spacing.l)

                    VStack(spacing: Theme.Spacing.l) {
                        Image(systemName: "steeringwheel.and.key")
                            .font(.system(size: 56, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 116, height: 116)
                            .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous))
                            .scaleEffect(appeared ? 1 : 0.8)
                            .opacity(appeared ? 1 : 0)

                        VStack(spacing: Theme.Spacing.s) {
                            Text("MyGarageMate")
                                .font(.largeTitle.bold())
                            Text("A beautiful, private home for your cars, services, reminders, and notes.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                    }

                    VStack(spacing: Theme.Spacing.m) {
                        ForEach(Array(highlights.enumerated()), id: \.offset) { index, item in
                            highlightRow(item)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 16)
                                .animation(Motion.spring.delay(0.15 + Double(index) * 0.07), value: appeared)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.xs)

                    Spacer(minLength: Theme.Spacing.l)

                    VStack(spacing: Theme.Spacing.m) {
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            viewModel.handleAppleResult(result, modelContext: modelContext)
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 54)
                        .clipShape(Capsule())
                        .accessibilityLabel("Continue with Apple")

                        #if DEBUG
                        Button {
                            viewModel.continueWithoutApple(modelContext: modelContext)
                        } label: {
                            Label("Continue without Apple", systemImage: "person.crop.circle.badge.checkmark")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.m)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("Continue without Apple for local testing")
                        #endif
                    }
                    .opacity(appeared ? 1 : 0)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Theme.Spacing.xl)
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(Motion.hero) { appeared = true }
            }
        }
    }

    private func highlightRow(_ item: (symbol: String, tint: Color, title: String, subtitle: String)) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: item.symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(item.tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.m)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.subtitle)")
    }
}
