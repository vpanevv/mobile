import SwiftData
import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car

    @State private var title = ""
    @State private var type: ReminderType = .custom
    @State private var hasDueDate = true
    @State private var dueDate = Date.now.addingTimeInterval(30 * 24 * 60 * 60)
    @State private var hasDueMileage = false
    @State private var dueMileage = 0.0
    @State private var hasReminderDate = true
    @State private var reminderDate = Date.now.addingTimeInterval(21 * 24 * 60 * 60)

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(ReminderType.allCases) { type in
                            Label(type.title, systemImage: type.symbolName).tag(type)
                        }
                    }
                }

                Section("Due") {
                    Toggle("Due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                    }

                    Toggle("Due mileage", isOn: $hasDueMileage)
                    if hasDueMileage {
                        TextField("Mileage", value: $dueMileage, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Notification") {
                    Toggle("Remind me", isOn: $hasReminderDate)
                    if hasReminderDate {
                        DatePicker("Reminder date", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let reminder = CarReminder(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            reminderType: type,
            dueDate: hasDueDate ? dueDate : nil,
            dueMileage: hasDueMileage ? dueMileage : nil,
            reminderDate: hasReminderDate ? reminderDate : nil
        )
        reminder.car = car
        car.reminders.append(reminder)

        do {
            try modelContext.save()
            HapticsManager.success()
            Task { await NotificationManager.schedule(reminder: reminder, for: car) }
            dismiss()
        } catch {
            assertionFailure("Failed to save reminder: \(error)")
        }
    }
}
