import Combine
import CoreLocation
import Foundation
import WeatherKit

struct WeatherSnapshot {
    let temperatureText: String
    let condition: String
    let symbolName: String
    let locality: String?
    let tip: String
}

@MainActor
final class WeatherViewModel: ObservableObject {
    enum LoadState {
        case idle
        case loading
        case denied
        case failed
        case loaded(WeatherSnapshot)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var attribution: WeatherAttribution?

    private let service = WeatherService.shared
    private let locationProvider = LocationProvider()
    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        state = .loading
        do {
            let location = try await locationProvider.currentLocation()
            let weather = try await service.weather(for: location)
            let current = weather.currentWeather

            let snapshot = WeatherSnapshot(
                temperatureText: current.temperature.formatted(
                    .measurement(
                        width: .abbreviated,
                        usage: .weather,
                        numberFormatStyle: .number.precision(.fractionLength(0))
                    )
                ),
                condition: current.condition.description,
                symbolName: current.symbolName,
                locality: await reverseGeocode(location),
                tip: WeatherTip.make(
                    temperatureCelsius: current.temperature.converted(to: .celsius).value,
                    symbolName: current.symbolName
                )
            )

            state = .loaded(snapshot)
            hasLoaded = true

            // Apple Weather attribution is required when displaying WeatherKit data.
            attribution = try? await service.attribution
        } catch let error as LocationError where error == .denied {
            state = .denied
        } catch {
            state = .failed
        }
    }

    private func reverseGeocode(_ location: CLLocation) async -> String? {
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        return placemarks?.first?.locality ?? placemarks?.first?.administrativeArea
    }
}

/// Maps the current conditions to a short, on-brand driving tip.
enum WeatherTip {
    static func make(temperatureCelsius celsius: Double, symbolName: String) -> String {
        let symbol = symbolName.lowercased()

        if symbol.contains("snow") || symbol.contains("sleet") || symbol.contains("hail") {
            return "Snow & ice — allow extra time and check your tyres."
        }
        if symbol.contains("bolt") {
            return "Storms about — take it easy and check your wipers."
        }
        if symbol.contains("rain") || symbol.contains("drizzle") {
            return "Wet roads — keep your distance and check your wipers."
        }
        if symbol.contains("fog") || symbol.contains("haze") || symbol.contains("smoke") {
            return "Low visibility — use your lights and slow down."
        }
        if celsius <= 0 {
            return "Freezing — check tyre pressure and your battery."
        }
        if celsius >= 32 {
            return "Hot out — check coolant and tyre pressure."
        }
        if celsius >= 24 {
            return "Warm and clear — great driving weather."
        }
        return "Good conditions for a drive today."
    }
}
