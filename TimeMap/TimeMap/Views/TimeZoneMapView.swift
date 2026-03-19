import MapKit
import SwiftUI

struct TimeZoneMapView: View {
    @ObservedObject var viewModel: TimeMapViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let selectedCoordinate = viewModel.selectedMapCoordinate {
                    Marker("Selected location", coordinate: selectedCoordinate)
                        .tint(TimeMapPalette.sunrise)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Label("Tap the map to choose a city", systemImage: "hand.tap.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .timeMapGlass(cornerRadius: 18, tint: TimeMapGradient.aurora)
                    .padding(12)
            }
            .shadow(color: TimeMapPalette.shadow, radius: 22, y: 14)
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if let coordinate = proxy.convert(value.location, from: .local) {
                            viewModel.handleMapTap(at: coordinate)
                        }
                    }
            )
        }
    }
}
