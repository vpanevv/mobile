import Foundation

struct AppContainer {
    let timeService: TimeService
    let searchService: LocationSearchService
    let locationResolver: LocationResolver
    let userLocationService: UserLocationService
    let favoritesStore: FavoritesStore

    static let live = AppContainer(
        timeService: TimeService(),
        searchService: LocationSearchService(),
        locationResolver: LocationResolver(),
        userLocationService: UserLocationService(),
        favoritesStore: FavoritesStore()
    )
}
