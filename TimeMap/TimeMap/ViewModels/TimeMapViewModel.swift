import Combine
import CoreLocation
import Foundation

@MainActor
final class TimeMapViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case search = "Search"
        case map = "Map"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .search: "magnifyingglass"
            case .map: "globe.americas.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .search: "Find cities instantly"
            case .map: "Tap the world visually"
            }
        }
    }

    @Published var mode: Mode = .search
    @Published var localTimeInfo: LocalTimeInfo
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var selectedLocationState = SelectedLocationState()
    @Published var selectedMapCoordinate: CLLocationCoordinate2D?

    private let timeService: TimeService
    private let searchService: LocationSearchService
    private let locationResolver: LocationResolver
    private let userLocationService: UserLocationService

    private var subscriptions = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private var selectedLocation: WorldLocation?
    private var localPlaceLabel: String?

    init(
        timeService: TimeService,
        searchService: LocationSearchService,
        locationResolver: LocationResolver,
        userLocationService: UserLocationService
    ) {
        self.timeService = timeService
        self.searchService = searchService
        self.locationResolver = locationResolver
        self.userLocationService = userLocationService
        self.localTimeInfo = timeService.makeLocalTimeInfo(now: Date(), placeLabel: nil)

        bindTicker()
        bindSearch()
        Task {
            await loadLocalPlace()
        }
    }

    var hasSearchQuery: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func selectSearchResult(_ result: SearchResult) {
        searchQuery = result.title
        searchResults = []
        resolveCoordinate(result.coordinate, source: .search)
    }

    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        mode = .map
        selectedMapCoordinate = coordinate
        resolveCoordinate(coordinate, source: .map)
    }

    func dismissSelectedLocation() {
        selectedLocation = nil
        selectedLocationState.status = .idle
    }

    private func bindTicker() {
        timeService.ticker()
            .receive(on: RunLoop.main)
            .sink { [weak self] date in
                self?.refreshTime(using: date)
            }
            .store(in: &subscriptions)
    }

    private func bindSearch() {
        $searchQuery
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(for: query)
            }
            .store(in: &subscriptions)
    }

    private func loadLocalPlace() async {
        localPlaceLabel = await userLocationService.requestLocalPlaceLabel()
        localTimeInfo = timeService.makeLocalTimeInfo(now: Date(), placeLabel: localPlaceLabel)
    }

    private func refreshTime(using date: Date) {
        localTimeInfo = timeService.makeLocalTimeInfo(now: date, placeLabel: localPlaceLabel)

        guard let selectedLocation else {
            return
        }

        selectedLocationState.status = .loaded(
            timeService.makeSnapshot(for: selectedLocation, relativeTo: .autoupdatingCurrent, now: date)
        )
    }

    private func performSearch(for query: String) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }

        isSearching = true
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled, let self else {
                return
            }

            do {
                let results = try await searchService.searchCities(matching: trimmedQuery)
                guard !Task.isCancelled else {
                    return
                }
                searchResults = results
                isSearching = false
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                searchResults = []
                isSearching = false
            }
        }
    }

    private func resolveCoordinate(_ coordinate: CLLocationCoordinate2D, source: WorldLocation.Source) {
        selectedLocationState.status = .loading(source)

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let location = try await locationResolver.resolve(coordinate: coordinate, source: source)
                selectedLocation = location
                selectedLocationState.status = .loaded(
                    timeService.makeSnapshot(for: location, relativeTo: .autoupdatingCurrent, now: Date())
                )
            } catch {
                selectedLocation = nil
                selectedLocationState.status = .failed(
                    error.localizedDescription.isEmpty
                        ? "We couldn't resolve a nearby city for that location."
                        : error.localizedDescription
                )
            }
        }
    }
}
