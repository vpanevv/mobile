import MapKit
import SwiftUI

struct TimeZoneMapView: View {
    @ObservedObject var viewModel: TimeMapViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                eyebrow: "Map",
                title: "Tap the globe",
                subtitle: "Choose any region and reveal its local moment."
            )

            InteractiveTimeMap(
                cameraPosition: $cameraPosition,
                selectedCoordinate: viewModel.selectedMapCoordinate,
                onTap: viewModel.handleMapTap(at:)
            )
            .frame(minHeight: 250, maxHeight: 290)

            switch viewModel.selectedLocationState.status {
            case .idle:
                StateMessageCard(
                    icon: "hand.tap.fill",
                    title: "Tap to explore",
                    message: "Select a point on the map to reveal the nearest place and time."
                )
            case .loading:
                StateMessageCard(
                    icon: "point.3.connected.trianglepath.dotted",
                    title: "Resolving map selection",
                    message: "Fetching locality, country, and timezone context."
                )
            case .loaded(let snapshot):
                LocationSnapshotCard(snapshot: snapshot)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .failed(let message):
                StateMessageCard(
                    icon: "mappin.slash.circle.fill",
                    title: "Couldn’t resolve that point",
                    message: message
                )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: viewModel.selectedLocationState)
    }
}

private struct InteractiveTimeMap: View {
    @Binding var cameraPosition: MapCameraPosition
    let selectedCoordinate: CLLocationCoordinate2D?
    let onTap: (CLLocationCoordinate2D) -> Void

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let selectedCoordinate {
                    Marker("Selected location", coordinate: selectedCoordinate)
                        .tint(TimeMapPalette.sunrise)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("World Time Map")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Tap anywhere to compare local time across the planet.")
                        .font(.caption)
                        .foregroundStyle(TimeMapPalette.mutedCloud)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .timeMapGlass(cornerRadius: 20, tint: TimeMapGradient.aurora)
                .padding(14)
            }
            .overlay(alignment: .bottomTrailing) {
                Label("Tap to select", systemImage: "hand.tap.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .timeMapGlass(cornerRadius: 18, tint: TimeMapGradient.sunrise)
                    .padding(14)
            }
            .shadow(color: TimeMapPalette.shadow, radius: 26, y: 16)
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if let coordinate = proxy.convert(value.location, from: .local) {
                            onTap(coordinate)
                        }
                    }
            )
        }
    }
}
