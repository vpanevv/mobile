import Foundation
import Combine

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [FavoriteWish] = []
    private let key = "favoriteWishes"

    init() { load() }

    func add(_ wish: FavoriteWish) { favorites.insert(wish, at: 0); save() }
    func remove(_ wish: FavoriteWish) { favorites.removeAll { $0.id == wish.id }; save() }
    func isFavorite(text: String) -> Bool { favorites.contains { $0.text == text } }

    func toggle(text: String, occasion: HolidayType, tone: WishTone, length: WishLength, recipientName: String?) {
        if let existing = favorites.first(where: { $0.text == text }) {
            remove(existing)
        } else {
            add(FavoriteWish(text: text, occasion: occasion, tone: tone, length: length, recipientName: recipientName))
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FavoriteWish].self, from: data) else { return }
        favorites = decoded
    }
}
