import Combine
import Foundation
import WidgetKit

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [FavoriteCity] = []

    static let appGroupID = "group.com.example.TimeMap.shared"
    static let storageKey = "timemap.favoriteCities"

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = UserDefaults(suiteName: FavoritesStore.appGroupID) ?? .standard,
        storageKey: String = FavoritesStore.storageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        load()
    }

    var hasFavorites: Bool {
        !favorites.isEmpty
    }

    func contains(_ location: WorldLocation) -> Bool {
        favorites.contains(where: { $0.id == FavoriteCity(location: location).id })
    }

    func toggle(_ location: WorldLocation) {
        let favorite = FavoriteCity(location: location)

        if contains(location) {
            remove(favorite)
        } else {
            add(favorite)
        }
    }

    func add(_ favorite: FavoriteCity) {
        guard !favorites.contains(where: { $0.id == favorite.id }) else {
            return
        }

        favorites.insert(favorite, at: 0)
        persist()
    }

    func remove(_ favorite: FavoriteCity) {
        favorites.removeAll { $0.id == favorite.id }
        persist()
    }

    func remove(location: WorldLocation) {
        remove(FavoriteCity(location: location))
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else {
            return
        }

        do {
            favorites = try JSONDecoder().decode([FavoriteCity].self, from: data)
        } catch {
            favorites = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(favorites)
            defaults.set(data, forKey: storageKey)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            assertionFailure("Failed to persist favorites: \(error.localizedDescription)")
        }
    }
}
