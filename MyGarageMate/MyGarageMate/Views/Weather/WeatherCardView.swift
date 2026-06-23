import SwiftUI
import WeatherKit

struct WeatherCardView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GlassCard(cornerRadius: Theme.Radius.card) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingContent
        case .denied:
            messageContent(
                symbol: "location.slash.fill",
                title: "Weather needs location",
                message: "Allow location access to see current conditions for your garage.",
                actionTitle: "Open Settings",
                action: openSettings
            )
        case .failed:
            messageContent(
                symbol: "exclamationmark.triangle.fill",
                title: "Weather unavailable",
                message: "Couldn't load the current conditions.",
                actionTitle: "Try Again",
                action: { Task { await viewModel.load() } }
            )
        case .loaded(let snapshot):
            loadedContent(snapshot)
        }
    }

    private func loadedContent(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .center, spacing: Theme.Spacing.l) {
                Image(systemName: snapshot.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 40))
                    .frame(width: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.temperatureText)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())

                    Text(localityLine(snapshot))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            Label(snapshot.tip, systemImage: "car.fill")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            attributionFooter
        }
    }

    private func localityLine(_ snapshot: WeatherSnapshot) -> String {
        if let locality = snapshot.locality {
            return "\(locality) · \(snapshot.condition)"
        }
        return snapshot.condition
    }

    private var loadingContent: some View {
        HStack(spacing: Theme.Spacing.l) {
            ProgressView()
            Text("Loading weather…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
    }

    private func messageContent(symbol: String, title: String, message: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(actionTitle, action: action)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderless)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var attributionFooter: some View {
        if let attribution = viewModel.attribution {
            let markURL = colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
            Link(destination: attribution.legalPageURL) {
                HStack(spacing: 4) {
                    AsyncImage(url: markURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Text(attribution.serviceName)
                            .font(.caption2)
                    }
                    .frame(height: 14)
                }
            }
            .foregroundStyle(.tertiary)
            .accessibilityLabel("Weather data attribution")
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
