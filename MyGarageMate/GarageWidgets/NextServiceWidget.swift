import SwiftUI
import WidgetKit

struct NextServiceWidget: Widget {
    let kind = "NextServiceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GarageProvider()) { entry in
            NextServiceWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Service")
        .description("See the next maintenance coming up across your garage.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextServiceWidgetView: View {
    let entry: GarageEntry
    @Environment(\.widgetFamily) private var family

    private var reminder: ReminderSnapshot? { entry.snapshot.nextReminder }

    var body: some View {
        if let reminder {
            content(for: reminder)
        } else {
            emptyState
        }
    }

    private func content(for reminder: ReminderSnapshot) -> some View {
        let tint = Color(sharedStatus: reminder.statusRawValue)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: reminder.symbolName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
                Image(systemName: "car.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(reminder.title)
                .font(.headline)
                .lineLimit(2)

            Text(reminder.carName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let dueDate = reminder.dueDate {
                Text(dueDate, format: .relative(presentation: .named))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
            } else if let dueMileage = reminder.dueMileage {
                Text("at \(dueMileage.formatted(.number.precision(.fractionLength(0)))) \(reminder.mileageUnit)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.green)
            Spacer(minLength: 0)
            Text("All clear")
                .font(.headline)
            Text("No upcoming service")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
