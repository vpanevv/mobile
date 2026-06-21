import SwiftData
import SwiftUI

struct ServiceHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car
    @State private var recordPendingDeletion: ServiceRecord?
    @State private var recordPendingEdit: ServiceRecord?

    var body: some View {
        Group {
            if car.serviceRecordsNewestFirst.isEmpty {
                EmptyStateView(
                    symbolName: "wrench.and.screwdriver",
                    title: "No service history yet",
                    message: "Add oil changes, repairs, insurance, inspections, and receipts as they happen."
                )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(car.serviceRecordsNewestFirst.enumerated()), id: \.element.id) { index, record in
                        serviceTimelineRow(record, isLast: index == car.serviceRecordsNewestFirst.count - 1)
                            .contextMenu {
                                Button {
                                    recordPendingEdit = record
                                } label: {
                                    Label("Edit Service", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    recordPendingDeletion = record
                                } label: {
                                    Label("Delete Service", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { recordPendingEdit != nil },
                set: { if !$0 { recordPendingEdit = nil } }
            )
        ) {
            if let recordPendingEdit {
                EditServiceRecordView(record: recordPendingEdit, car: car)
            }
        }
        .confirmationDialog(
            "Delete service record?",
            isPresented: Binding(
                get: { recordPendingDeletion != nil },
                set: { if !$0 { recordPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Record", role: .destructive) {
                deletePendingRecord()
            }
            Button("Cancel", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: {
            Text("This removes the selected service record from this device.")
        }
    }

    private func deletePendingRecord() {
        guard let record = recordPendingDeletion else { return }
        modelContext.delete(record)
        do {
            try modelContext.save()
            HapticsManager.warning()
        } catch {
            assertionFailure("Failed to delete service record: \(error)")
        }
        recordPendingDeletion = nil
    }

    private func serviceTimelineRow(_ record: ServiceRecord, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: record.category.symbolName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(record.category.tint.gradient, in: Circle())
                    .shadow(color: record.category.tint.opacity(0.3), radius: 10, y: 5)

                if !isLast {
                    Rectangle()
                        .fill(Color(.separator).opacity(0.38))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .frame(width: 42)

            SwipeActionsRow {
                recordPendingEdit = record
            } onDelete: {
                recordPendingDeletion = record
            } content: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.title)
                            .font(.headline)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(record.category.title)
                            Text("•")
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                        if let mileage = record.mileage {
                            Label("\(mileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)", systemImage: "gauge.with.dots.needle.67percent")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        if let shopName = record.shopName {
                            Label(shopName, systemImage: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    CurrencyAmountView(amountMinor: record.amountMinor, currencyCode: record.currencyCode)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.l)
                .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct EditServiceRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let record: ServiceRecord
    let car: Car

    @State private var title: String
    @State private var category: ServiceCategory
    @State private var date: Date
    @State private var amountText: String
    @State private var currencyCode: String
    @State private var mileage: Double
    @State private var shopName: String
    @State private var notes: String
    @State private var receiptImageData: Data?

    init(record: ServiceRecord, car: Car) {
        self.record = record
        self.car = car
        _title = State(initialValue: record.title)
        _category = State(initialValue: record.category)
        _date = State(initialValue: record.date)
        _amountText = State(initialValue: Self.amountText(fromMinor: record.amountMinor))
        _currencyCode = State(initialValue: record.currencyCode)
        _mileage = State(initialValue: record.mileage ?? car.currentMileage)
        _shopName = State(initialValue: record.shopName ?? "")
        _notes = State(initialValue: record.notes ?? "")
        _receiptImageData = State(initialValue: record.receiptImageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    HStack(spacing: 12) {
                        Image(systemName: category.symbolName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.tint)
                            .frame(width: 42, height: 42)
                            .background(.thinMaterial, in: Circle())
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.title)
                                .font(.headline)
                            Text("Selected service type")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Selected service type \(category.title)")

                    TextField("Title", text: $title)
                        .accessibilityLabel("Service title")

                    Picker("Category", selection: $category) {
                        ForEach(ServiceCategory.allCases) { category in
                            Label(category.title, systemImage: category.symbolName).tag(category)
                        }
                    }
                    .accessibilityLabel("Service category")

                    DatePicker("Date", selection: $date, displayedComponents: .date)
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
                    TextField("Mileage", value: $mileage, format: .number)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Service mileage")

                    TextField("Shop name", text: $shopName)
                        .accessibilityLabel("Shop name")

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Service notes")

                    CarPhotoPickerView(imageData: $receiptImageData, title: "Receipt Image", systemImage: "doc.text.image")
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(validationMessage != nil)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add a service title before saving."
        }
        if mileage < 0 {
            return "Mileage cannot be negative."
        }
        return nil
    }

    private func save() {
        guard validationMessage == nil else { return }
        record.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        record.category = category
        record.date = date
        record.amountMinor = CurrencyFormatter.minorUnits(from: amountText)
        record.currencyCode = currencyCode
        record.mileage = mileage > 0 ? mileage : nil
        record.shopName = shopName.nilIfBlankForEdit
        record.notes = notes.nilIfBlankForEdit
        record.receiptImageData = receiptImageData
        record.updatedAt = .now

        if mileage > car.currentMileage {
            car.currentMileage = mileage
        }

        do {
            try modelContext.save()
            HapticsManager.success()
            dismiss()
        } catch {
            assertionFailure("Failed to edit service record: \(error)")
        }
    }

    private static func amountText(fromMinor amountMinor: Int) -> String {
        String(format: "%.2f", Double(amountMinor) / 100)
    }
}

private extension String {
    var nilIfBlankForEdit: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
