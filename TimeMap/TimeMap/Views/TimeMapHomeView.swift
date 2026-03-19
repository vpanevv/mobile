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
                .padding(16)
                .timeMapGlass(cornerRadius: 30, tint: TimeMapGradient.aurora)
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
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("A premium view of time across the planet.")
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
            }

            Spacer()

            Image(systemName: "globe.europe.africa.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(14)
                .timeMapGlass(cornerRadius: 20, tint: TimeMapGradient.aurora)
        }
    }
}

private struct SearchExplorerView: View {
    @ObservedObject var viewModel: TimeMapViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                eyebrow: "Explore",
                title: "Search any city",
                subtitle: "Find a place instantly and compare its clock with yours."
            )

            CitySearchField(text: $viewModel.searchQuery)

            if viewModel.isSearching {
                StateMessageCard(
                    icon: "clock.arrow.circlepath",
                    title: "Searching cities",
                    message: "Looking up places and timezone matches."
                )
            } else if viewModel.hasSearchQuery && viewModel.searchResults.isEmpty {
                StateMessageCard(
                    icon: "magnifyingglass",
                    title: "No results yet",
                    message: "Try a broader city name or use a nearby major city."
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
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 72)
                        }
                    }
                }
                .timeMapGlass(cornerRadius: 24, tint: TimeMapGradient.aurora)
            } else {
                StateMessageCard(
                    icon: "sparkles",
                    title: "Start exploring",
                    message: "Search a city to reveal its current time, timezone, and how far ahead or behind it is."
                )
            }

            SelectedSnapshotSection(state: viewModel.selectedLocationState)
        }
    }
}

private struct SelectedSnapshotSection: View {
    let state: SelectedLocationState

    var body: some View {
        switch state.status {
        case .idle:
            EmptyView()
        case .loading:
            StateMessageCard(
                icon: "network.badge.shield.half.filled",
                title: "Resolving location",
                message: "Pulling the latest city and timezone data."
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
