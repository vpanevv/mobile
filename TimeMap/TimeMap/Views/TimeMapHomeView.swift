import SwiftUI

struct TimeMapHomeView: View {
    @ObservedObject var viewModel: TimeMapViewModel
    @ObservedObject var favoritesStore: FavoritesStore
    let timeService: TimeService

    @State private var isPresentingFavorites = false

    var body: some View {
        ZStack {
            TimeMapBackgroundView()

            VStack(alignment: .leading, spacing: 20) {
                header
                LocalTimeHeroCard(
                    info: viewModel.localTimeInfo,
                    favoritesCount: favoritesStore.favorites.count,
                    openFavorites: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                            isPresentingFavorites = true
                        }
                    }
                )
                ModePickerBar(selectedMode: $viewModel.mode)
                activePanel
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)

            selectedLocationOverlay
        }
        .sheet(isPresented: $isPresentingFavorites) {
            FavoritesView(
                favoritesStore: favoritesStore,
                timeService: timeService,
                openFavorite: { favorite in
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        viewModel.showFavorite(favorite)
                    }
                }
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TimeMap")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Choose how you want to explore time.")
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var activePanel: some View {
        switch viewModel.mode {
        case .search:
            SearchPanel(viewModel: viewModel)
        case .map:
            MapPanel(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var selectedLocationOverlay: some View {
        switch viewModel.selectedLocationState.status {
        case .idle:
            EmptyView()
        case .loading:
            overlayBackdrop
                .overlay(alignment: .bottom) {
                    StateMessageCard(
                        icon: "clock.arrow.circlepath",
                        title: "Loading city",
                        message: "Resolving time and timezone details."
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        case .failed(let message):
            overlayBackdrop
                .overlay(alignment: .bottom) {
                    StateMessageCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Location unavailable",
                        message: message
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        case .loaded(let snapshot):
            overlayBackdrop
                .overlay {
                    GeometryReader { proxy in
                        SelectedCityPopupCard(
                            snapshot: snapshot,
                            isFavorite: favoritesStore.contains(snapshot.location),
                            toggleFavorite: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    favoritesStore.toggle(snapshot.location)
                                }
                            },
                            dismiss: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                    viewModel.dismissSelectedLocation()
                                }
                            }
                        )
                        .padding(.horizontal, 18)
                        .padding(.vertical, 24)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: max(320, proxy.size.height - 52),
                            alignment: .center
                        )
                    }
                }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.96).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }

    private var overlayBackdrop: some View {
        Rectangle()
            .fill(.black.opacity(0.26))
            .ignoresSafeArea()
    }
}

private struct SearchPanel: View {
    @ObservedObject var viewModel: TimeMapViewModel

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Search cities")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Type a city to compare its local time instantly.")
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
            }
            .frame(maxWidth: .infinity)

            CitySearchField(text: $viewModel.searchQuery)

            if viewModel.isSearching {
                StateMessageCard(
                    icon: "magnifyingglass.circle.fill",
                    title: "Searching",
                    message: "Finding matching cities."
                )
            } else if !viewModel.searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.searchResults.prefix(4)) { result in
                        Button {
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                                viewModel.selectSearchResult(result)
                            }
                        } label: {
                            CitySearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)

                        if result.id != viewModel.searchResults.prefix(4).last?.id {
                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 72)
                        }
                    }
                }
                .timeMapGlass(cornerRadius: 24, tint: TimeMapGradient.aurora)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MapPanel: View {
    @ObservedObject var viewModel: TimeMapViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore the world")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            InteractiveGlobeView(viewModel: viewModel)
                .frame(height: 384)
        }
    }
}
