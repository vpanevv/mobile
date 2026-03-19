import MapKit
import SwiftUI

struct TimeZoneMapView: View {
    @ObservedObject var viewModel: TimeMapViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Text("Tap the world clock")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("Map mode")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.68))
            }

            InteractiveTimeMap(
                cameraPosition: $cameraPosition,
                selectedCoordinate: viewModel.selectedMapCoordinate,
                onTap: viewModel.handleMapTap(at:)
            )
            .frame(minHeight: 250, maxHeight: 280)

            switch viewModel.selectedLocationState.status {
            case .idle:
                StateMessageCard(
                    icon: "hand.tap.fill",
                    title: "Tap to explore",
                    message: "Drop into any region and TimeMap will surface nearby place and time details."
                )
            case .loading:
                StateMessageCard(
                    icon: "point.3.connected.trianglepath.dotted",
                    title: "Resolving map selection",
                    message: "Fetching locality, country, timezone, and comparison data."
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
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("World Time Map")
                        .font(.headline.weight(.semibold))
                    Text("Tap anywhere to compare local time with a new place.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(16)
            }
            .overlay(alignment: .bottomTrailing) {
                Label("Tap to pick", systemImage: "hand.tap.fill")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.28), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(16)
            }
            .shadow(color: TimeMapPalette.shadow, radius: 22, y: 14)
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
