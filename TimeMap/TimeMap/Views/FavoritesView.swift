import SwiftUI

struct FavoritesView: View {
    @ObservedObject var favoritesStore: FavoritesStore
    let timeService: TimeService
    let openFavorite: (FavoriteCity) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                TimeMapBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        if favoritesStore.favorites.isEmpty {
                            FavoritesEmptyState()
                        } else {
                            SavedCitiesCarousel(
                                favorites: favoritesStore.favorites,
                                timeService: timeService,
                                openFavorite: { favorite in
                                    openFavorite(favorite)
                                    dismiss()
                                },
                                removeFavorite: { favorite in
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                        favoritesStore.remove(favorite)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Favorites")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your saved cities, ready whenever you want a quick time check.")
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
            }

            Spacer(minLength: 12)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.12), in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FavoritesEmptyState: View {
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(TimeMapGradient.sunrise.opacity(0.26))
                    .frame(width: 92, height: 92)
                    .blur(radius: 8)

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 82, height: 82)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            VStack(spacing: 8) {
                Text("No favorite cities yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Save a city from its time card and it will appear here for one-tap access later.")
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 34)
        .frame(maxWidth: .infinity)
        .timeMapGlass(cornerRadius: 30, tint: TimeMapGradient.sunrise)
    }
}
