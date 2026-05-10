import SwiftUI

struct ReminderRow: View {
    let reminder: CarReminder
    let car: Car

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.reminderType.symbolName)
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                Text(dueText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
