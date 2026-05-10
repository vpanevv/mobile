import SwiftData
import SwiftUI

struct AddServiceRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car
    let profile: UserProfile

    @State private var title = ""
    @State private var category: ServiceCategory = .oil
    @State private var date = Date.now
    @State private var mileage = 0.0
    @State private var amountText = ""
    @State private var currencyCode = "EUR"
    @State private var shopName = ""
    @State private var notes = ""
    @State private var receiptImageData: Data?
    @State private var createFollowUpReminder = false
    @State private var reminderDate = Date.now.addingTimeInterval(180 * 24 * 60 * 60)
    @State private var reminderMileage = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(ServiceCategory.allCases) { category in
                            Label(category.title, systemImage: category.symbolName).tag(category)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Mileage", value: $mileage, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section("Cost") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $currencyCode) {
                        Text("EUR").tag("EUR")
                        Text("USD").tag("USD")
                    }
                    .pickerStyle(.segmented)
                }

                DisclosureGroup("Optional details") {
                    TextField("Shop name", text: $shopName)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    CarPhotoPickerView(imageData: $receiptImageData, title: "Receipt Image", systemImage: "doc.text.image")
                }

                if category == .oil || category == .insurance || category == .inspection {
                    Section("Follow-up") {
                        Toggle(followUpTitle, isOn: $createFollowUpReminder)
                        if createFollowUpReminder {
                            DatePicker("Due date", selection: $reminderDate, displayedComponents: .date)
                            if category == .oil {
                                TextField("Due mileage", value: $reminderMileage, format: .number)
                                    .keyboardType(.decimalPad)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Service")
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
            .onAppear {
                mileage = car.currentMileage
                currencyCode = profile.preferredCurrencyCode
                reminderMileage = car.currentMileage + 10_000
            }
            .onChange(of: category) { _, newValue in
                createFollowUpReminder = false
                if newValue == .oil {
                    reminderDate = Date.now.addingTimeInterval(180 * 24 * 60 * 60)
                    reminderMileage = car.currentMileage + 10_000
                } else {
                    reminderDate = Date.now.addingTimeInterval(365 * 24 * 60 * 60)
                }
            }
        }
    }

    private var followUpTitle: String {
        switch category {
        case .oil:
            "Create next oil change reminder"
        case .insurance:
            "Create insurance expiry reminder"
        case .inspection:
            "Create inspection renewal reminder"
        default:
            "Create reminder"
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = ServiceRecord(
            title: trimmedTitle,
            category: category,
            date: date,
            mileage: mileage > 0 ? mileage : nil,
            amountMinor: CurrencyFormatter.minorUnits(from: amountText),
            currencyCode: currencyCode,
            shopName: shopName.nilIfBlank,
            notes: notes.nilIfBlank,
            receiptImageData: receiptImageData
        )
        record.car = car
        car.serviceRecords.append(record)

        if mileage > car.currentMileage {
            car.currentMileage = mileage
        }

        let reminder = followUpReminderIfNeeded()
        if let reminder {
            reminder.car = car
            car.reminders.append(reminder)
        }

        do {
            try modelContext.save()
            HapticsManager.success()
            if let reminder {
                Task { await NotificationManager.schedule(reminder: reminder, for: car) }
            }
            dismiss()
        } catch {
            assertionFailure("Failed to save service record: \(error)")
        }
    }

    private func followUpReminderIfNeeded() -> CarReminder? {
        guard createFollowUpReminder else { return nil }

        switch category {
        case .oil:
            return CarReminder(title: "Next oil change", reminderType: .oilChange, dueDate: reminderDate, dueMileage: reminderMileage, reminderDate: Calendar.current.date(byAdding: .day, value: -14, to: reminderDate))
        case .insurance:
            return CarReminder(title: "Insurance renewal", reminderType: .insurance, dueDate: reminderDate, reminderDate: Calendar.current.date(byAdding: .day, value: -30, to: reminderDate))
        case .inspection:
            return CarReminder(title: "Inspection renewal", reminderType: .inspection, dueDate: reminderDate, reminderDate: Calendar.current.date(byAdding: .day, value: -21, to: reminderDate))
        default:
            return nil
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
