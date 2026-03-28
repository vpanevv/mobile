import SwiftUI

struct SavedCitiesCarousel: View {
    let favorites: [FavoriteCity]
    let timeService: TimeService
    let openFavorite: (FavoriteCity) -> Void
    let removeFavorite: (FavoriteCity) -> Void

    @State private var selection: FavoriteCity.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Saved cities")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(favorites.count > 1 ? "Swipe through your cities for quick time checks." : "Your saved city is ready for a one-tap reopen.")
                        .font(.subheadline)
                        .foregroundStyle(TimeMapPalette.mutedCloud)
                }

                Spacer(minLength: 12)

                if favorites.count > 1 {
                    pageIndicator
                }
            }

            TabView(selection: selectedFavoriteBinding) {
                ForEach(favorites) { favorite in
                    SavedCityCarouselCard(
                        favorite: favorite,
                        timeService: timeService,
                        openFavorite: { openFavorite(favorite) },
                        removeFavorite: { removeFavorite(favorite) }
                    )
                    .tag(favorite.id)
                    .padding(.horizontal, 2)
                }
            }
            .frame(height: 282)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onAppear {
            selection = selection ?? favorites.first?.id
        }
        .onChange(of: favorites) { _, newValue in
            if let selection, newValue.contains(where: { $0.id == selection }) {
                return
            }

            self.selection = newValue.first?.id
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(favorites) { favorite in
                Capsule(style: .continuous)
                    .fill(favorite.id == selection ? Color.white.opacity(0.92) : Color.white.opacity(0.22))
                    .frame(width: favorite.id == selection ? 22 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: selection)
    }

    private var selectedFavoriteBinding: Binding<FavoriteCity.ID?> {
        Binding(
            get: {
                selection ?? favorites.first?.id
            },
            set: { selection = $0 }
        )
    }
}

private struct SavedCityCarouselCard: View {
    let favorite: FavoriteCity
    let timeService: TimeService
    let openFavorite: () -> Void
    let removeFavorite: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let snapshot = FavoriteCitySnapshot(
                favorite: favorite,
                timeService: timeService,
                now: context.date
            )

            ZStack(alignment: .topTrailing) {
                Button(action: openFavorite) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 14) {
                            HStack(alignment: .center, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.14))
                                        .frame(width: 58, height: 58)

                                    Text(snapshot.flag)
                                        .font(.system(size: 31))
                                }
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                )

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(snapshot.favorite.city)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Text(snapshot.favorite.country)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.white.opacity(0.76))

                                    Text(snapshot.timeZoneName)
                                        .font(.caption)
                                        .foregroundStyle(TimeMapPalette.mutedCloud)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 48)
                        }

                        HStack(alignment: .bottom, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(snapshot.currentTimeText)
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                                    .contentTransition(.numericText())

                                Text(snapshot.dateText)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.white.opacity(0.72))
                            }

                            Spacer(minLength: 16)

                            VStack(alignment: .trailing, spacing: 10) {
                                Label(snapshot.moodTitle, systemImage: snapshot.moodIcon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(snapshot.moodTint)

                                Text(snapshot.differenceText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                if let offsetText = snapshot.offsetText {
                                    Text(offsetText)
                                        .font(.caption)
                                        .foregroundStyle(TimeMapPalette.mutedCloud)
                                }
                            }
                        }
                    }
                    .padding(22)
                    .padding(.trailing, 42)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(cardBackground(snapshot))
                    .overlay(cardStroke)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: snapshot.shadowColor, radius: 28, y: 16)
                }
                .buttonStyle(.plain)

                Button(action: removeFavorite) {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.12), in: Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
        }
    }

    private func cardBackground(_ snapshot: FavoriteCitySnapshot) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(snapshot.gradient)
                    .opacity(0.96)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear, Color.black.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
    }
}
