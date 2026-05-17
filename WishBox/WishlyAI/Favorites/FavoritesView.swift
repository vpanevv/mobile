import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var store: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("wishlyai.isDark") private var isDark: Bool = true

    var body: some View {
        ZStack {
            NeuralBackground()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Favorites")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("\(store.favorites.count) saved \(store.favorites.count == 1 ? "wish" : "wishes")")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.5))
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary.opacity(0.7))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)

                if store.favorites.isEmpty {
                    EmptyFavoritesState()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(store.favorites) { wish in
                                FavoriteWishCard(wish: wish) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        store.remove(wish)
                                    }
                                }
                                .environmentObject(store)
                                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
    }
}
