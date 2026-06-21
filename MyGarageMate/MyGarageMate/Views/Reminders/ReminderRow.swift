import SwiftUI

struct ReminderRow: View {
    let reminder: CarReminder
    let car: Car

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: reminder.reminderType.symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Theme.accent.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.headline)
                Text(dueText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.l)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var dueText: String {
        if let dueDate = reminder.dueDate, let dueMileage = reminder.dueMileage {
            return "\(car.make) \(car.model) · \(dueDate.formatted(date: .abbreviated, time: .omitted)) or \(dueMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)"
        }
        if let dueDate = reminder.dueDate {
            return "\(car.make) \(car.model) · \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        }
        if let dueMileage = reminder.dueMileage {
            return "\(car.make) \(car.model) · \(dueMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)"
        }
        return "\(car.make) \(car.model)"
    }
}
