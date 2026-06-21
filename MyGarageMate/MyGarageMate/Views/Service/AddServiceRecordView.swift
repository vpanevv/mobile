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
    @State private var isApplyingPreset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick presets") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                        ForEach(ServicePreset.allCases) { preset in
                            Button {
                                apply(preset)
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: preset.category.symbolName)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(preset.color)
                                        .frame(width: 38, height: 38)
                                        .background(preset.color.opacity(0.12), in: Circle())

                                    Text(preset.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.82)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Use \(preset.title) preset")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }

                Section("Service") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Service title")
                    Picker("Category", selection: $category) {
                        ForEach(ServiceCategory.allCases) { category in
                            Label(category.title, systemImage: category.symbolName).tag(category)
                        }
                    }
                    .accessibilityLabel("Service category")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Mileage", value: $mileage, format: .number)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Service mileage")
                }

                Section("Cost") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Service cost amount")
                    Picker("Currency", selection: $currencyCode) {
                        Text("EUR").tag("EUR")
                        Text("USD").tag("USD")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Service currency")
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

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityLabel(validationMessage)
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
                        .disabled(!canSave)
                        .accessibilityLabel("Save service record")
                }
            }
            .onAppear {
                mileage = car.currentMileage
                currencyCode = profile.preferredCurrencyCode
                reminderMileage = car.currentMileage + 10_000
            }
            .onChange(of: category) { _, newValue in
                if isApplyingPreset {
                    isApplyingPreset = false
                    return
                }
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

    private var canSave: Bool {
        validationMessage == nil
    }

    private var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add a service title before saving."
        }
        if mileage < 0 {
            return "Mileage cannot be negative."
        }
        if createFollowUpReminder, category == .oil, reminderMileage < 0 {
            return "Reminder mileage cannot be negative."
        }
        return nil
    }

    private func save() {
        guard canSave else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let createdAt = Date.now
        let record = ServiceRecord(
            title: trimmedTitle,
            category: category,
            date: date,
            mileage: mileage > 0 ? mileage : nil,
            amountMinor: CurrencyFormatter.minorUnits(from: amountText),
            currencyCode: currencyCode,
            shopName: shopName.nilIfBlank,
            notes: notes.nilIfBlank,
            receiptImageData: receiptImageData,
            createdAt: createdAt,
            updatedAt: createdAt
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

    private func apply(_ preset: ServicePreset) {
        isApplyingPreset = category != preset.category
        title = preset.defaultTitle
        category = preset.category
        createFollowUpReminder = preset.createsReminder

        switch preset.category {
        case .oil:
            reminderDate = Date.now.addingTimeInterval(180 * 24 * 60 * 60)
            reminderMileage = max(car.currentMileage, mileage) + 10_000
        case .insurance:
            reminderDate = Date.now.addingTimeInterval(365 * 24 * 60 * 60)
        case .inspection:
            reminderDate = Date.now.addingTimeInterval(365 * 24 * 60 * 60)
        default:
            break
        }

        HapticsManager.lightTap()
    }
}

private enum ServicePreset: String, CaseIterable, Identifiable {
    case oilAndFilter
    case insurance
    case inspection
    case tires
    case brakes
    case repair

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oilAndFilter: "Oil + Filter"
        case .insurance: "Insurance"
        case .inspection: "Inspection"
        case .tires: "Tires"
        case .brakes: "Brakes"
        case .repair: "Repair"
        }
    }

    var defaultTitle: String {
        switch self {
        case .oilAndFilter: "Oil and filter"
        case .insurance: "Annual insurance"
        case .inspection: "Inspection"
        case .tires: "Tire service"
        case .brakes: "Brake service"
        case .repair: "Repair"
        }
    }

    var category: ServiceCategory {
        switch self {
        case .oilAndFilter: .oil
        case .insurance: .insurance
        case .inspection: .inspection
        case .tires: .tires
        case .brakes: .brakes
        case .repair: .other
        }
    }

    var createsReminder: Bool {
        switch self {
        case .oilAndFilter, .insurance, .inspection: true
        case .tires, .brakes, .repair: false
        }
    }

    var color: Color {
        switch self {
        case .oilAndFilter: .blue
        case .insurance: .cyan
        case .inspection: .mint
        case .tires: .indigo
        case .brakes: .red
        case .repair: .orange
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
