import SwiftUI
import Combine

enum AppAppearance: String, CaseIterable {
    case dark
    case light

    var colorScheme: ColorScheme {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }

    var title: String {
        switch self {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        }
    }

    var symbolName: String {
        switch self {
        case .dark:
            return "moon.stars.fill"
        case .light:
            return "sun.max.fill"
        }
    }

    var isDark: Bool {
        self == .dark
    }
}

@MainActor
final class AppearanceStore: ObservableObject {
    @Published var appearance: AppAppearance {
        didSet {
            userDefaults.set(appearance.rawValue, forKey: storageKey)
        }
    }

    private let userDefaults = UserDefaults.standard
    private let storageKey = "todoai.appearance"

    init() {
        if let storedValue = userDefaults.string(forKey: storageKey),
           let storedAppearance = AppAppearance(rawValue: storedValue) {
            self.appearance = storedAppearance
        } else {
            self.appearance = .dark
        }
    }
}
