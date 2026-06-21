import SwiftUI
import WidgetKit

struct SpendWidget: Widget {
    let kind = "SpendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GarageProvider()) { entry in
            SpendWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Garage Spend")
        .description("Track how much you've spent on your cars this year.")
        .supportedFamilies([.systemSmall])
    }
}

struct SpendWidgetView: View {
    let entry: GarageEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
            }

            Spacer(minLength: 0)

            Text("This year")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(SharedCurrencyFormatter.string(fromMinor: entry.snapshot.totalSpentThisYearMinor, currencyCode: entry.snapshot.currencyCode))
                .font(.title3.weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("\(entry.snapshot.carCount) \(entry.snapshot.carCount == 1 ? "car" : "cars")")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}
