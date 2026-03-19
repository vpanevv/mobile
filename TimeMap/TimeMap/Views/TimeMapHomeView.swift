import SwiftUI

struct TimeMapHomeView: View {
    @ObservedObject var viewModel: TimeMapViewModel

    var body: some View {
        ZStack {
            TimeMapBackgroundView()

            VStack(spacing: 14) {
                header
                LocalTimeHeroCard(info: viewModel.localTimeInfo)
                ModePickerBar(selectedMode: $viewModel.mode)

                Group {
                    switch viewModel.mode {
                    case .search:
                        SearchExplorerView(viewModel: viewModel)
                    case .map:
                        TimeZoneMapView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TimeMap")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text("Compare time beautifully across the world.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            Spacer()

            Image(systemName: "globe.badge.chevron.backward")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(14)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 2)
    }
}

private struct SearchExplorerView: View {
    @ObservedObject var viewModel: TimeMapViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Text("Search any city")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("Live compare")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.68))
            }

            CitySearchField(text: $viewModel.searchQuery)

            if viewModel.isSearching {
                StateMessageCard(
                    icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    title: "Searching cities",
                    message: "Finding matching places and timezone context."
                )
            } else if viewModel.hasSearchQuery && viewModel.searchResults.isEmpty {
                StateMessageCard(
                    icon: "magnifyingglass",
                    title: "No cities found",
                    message: "Try a larger nearby city or simplify the search terms."
                )
            } else if !viewModel.searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.searchResults.prefix(3)) { result in
                        Button {
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                                viewModel.selectSearchResult(result)
                            }
                        } label: {
                            CitySearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)

                        if result.id != viewModel.searchResults.prefix(3).last?.id {
                            Divider()
                                .overlay(Color.primary.opacity(0.08))
                                .padding(.leading, 78)
                        }
                    }
                }
                .timeMapCard()
            } else {
                StateMessageCard(
                    icon: "sparkles",
                    title: "Start with a city",
                    message: "Search for a destination and TimeMap will show the current time, timezone, and difference from you."
                )
            }

            SelectedSnapshotSection(state: viewModel.selectedLocationState)
        }
    }
}

private struct SelectedSnapshotSection: View {
    let state: SelectedLocationState

    var body: some View {
        VStack(spacing: 10) {
            switch state.status {
            case .idle:
                EmptyView()
            case .loading:
                StateMessageCard(
                    icon: "network.badge.shield.half.filled",
                    title: "Resolving location",
                    message: "Pulling the nearest meaningful place and live time data."
                )
            case .loaded(let snapshot):
                LocationSnapshotCard(snapshot: snapshot)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .failed(let message):
                StateMessageCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Location unavailable",
                    message: message
                )
            }
        }
    }
}
