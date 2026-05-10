import SwiftUI

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbolName)
                .font(.system(size: 42, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: 82, height: 82)
                .background(.thinMaterial, in: Circle())

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle, let action {
                Button(action: action) {
                    Label(buttonTitle, systemImage: "plus")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .accessibilityElement(children: .combine)
    }
}
