import SwiftUI

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: symbolName)
                .font(.system(size: 46, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Theme.accent)
                .frame(width: 104, height: 104)
                .glassEffect(.regular, in: Circle())
                .symbolEffect(.bounce, options: .repeat(.periodic(delay: 2.4)), value: appeared)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: Theme.Spacing.s) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            if let buttonTitle, let action {
                Button {
                    HapticsManager.soft()
                    action()
                } label: {
                    Label(buttonTitle, systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.m)
                }
                .buttonStyle(.glassProminent)
                .opacity(appeared ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
        .onAppear {
            withAnimation(Motion.hero) { appeared = true }
        }
        .accessibilityElement(children: .combine)
    }
}
