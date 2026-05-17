import SwiftUI

struct EmptyFavoritesState: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.primary.opacity(0.25))
                .scaleEffect(pulse ? 1.06 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }

            Text("No favorites yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Tap the heart on any wish\nto save it here for later.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
