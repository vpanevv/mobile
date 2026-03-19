import CoreLocation
import Foundation

@MainActor
final class UserLocationService: NSObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func requestLocalPlaceLabel() async -> String? {
        guard CLLocationManager.locationServicesEnabled() else {
            return nil
        }

        let status = await requestAuthorizationIfNeeded()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        guard let coordinate = await requestLocation() else {
            return nil
        }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
            guard let placemark = placemarks.first else {
                return nil
            }

            if let city = placemark.locality, let country = placemark.country {
                return "\(city), \(country)"
            }

            if let region = placemark.administrativeArea, let country = placemark.country {
                return "\(region), \(country)"
            }

            return placemark.country
        } catch {
            return nil
        }
    }

    private func requestAuthorizationIfNeeded() async -> CLAuthorizationStatus {
        let currentStatus = manager.authorizationStatus
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func requestLocation() async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }
}

extension UserLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationContinuation?.resume(returning: manager.authorizationStatus)
            authorizationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationContinuation?.resume(returning: locations.first?.coordinate)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        Task { @MainActor in
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }
}
