import SwiftData
import PhotosUI
import SwiftUI
import UIKit

struct CarDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car
    let profile: UserProfile

    @State private var selectedSection: DetailSection = .overview
    @State private var isAddingService = false
    @State private var isAddingNote = false
    @State private var isAddingReminder = false
    @State private var isConfirmingDelete = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isEditingMileage = false
    @State private var mileageDraft = ""
    @State private var mileageValidationMessage: String?
    @State private var serviceReportURL: URL?
    @State private var serviceReportMessage: String?
    @State private var isGeneratingServiceReport = false
    @State private var isShowingServiceReportShareSheet = false
    @State private var isShowingThisYearServices = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero

                summaryCards
                    .padding(.horizontal)

                Picker("Section", selection: $selectedSection) {
                    ForEach(DetailSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                sectionContent
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(car.model)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button {
                    isAddingService = true
                } label: {
                    Label("Service Record", systemImage: "wrench.and.screwdriver.fill")
                }

                Button {
                    isAddingNote = true
                } label: {
                    Label("Mechanic Note", systemImage: "note.text.badge.plus")
                }

                Button {
                    isAddingReminder = true
                } label: {
                    Label("Reminder", systemImage: "bell.badge.fill")
                }

                Button {
                    generateServiceReport()
                } label: {
                    Label("Export Services Report", systemImage: "doc.richtext")
                }
                .disabled(isGeneratingServiceReport)

                Divider()

                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete Car", systemImage: "trash")
                }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Car actions")
        }
        .sheet(isPresented: $isAddingService) {
            AddServiceRecordView(car: car, profile: profile)
        }
        .sheet(isPresented: $isAddingNote) {
            AddMechanicNoteView(car: car)
        }
        .sheet(isPresented: $isAddingReminder) {
            AddReminderView(car: car)
        }
        .sheet(isPresented: $isEditingMileage) {
            mileageEditor
        }
        .sheet(isPresented: $isShowingThisYearServices) {
            ThisYearServicesView(car: car, records: paidServicesThisYear)
        }
        .sheet(isPresented: $isShowingServiceReportShareSheet) {
            if let serviceReportURL {
                ServiceReportShareSheet(url: serviceReportURL)
                    .presentationDetents([.medium, .large])
            }
        }
        .alert(
            "Services Report",
            isPresented: Binding(
                get: { serviceReportMessage != nil },
                set: { if !$0 { serviceReportMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                serviceReportMessage = nil
            }
        } message: {
            Text(serviceReportMessage ?? "")
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                await updatePhoto(from: newValue)
            }
        }
        .confirmationDialog(
            "Delete this car?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Car", role: .destructive) {
                deleteCar()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes \(car.displayName) and all related service records, reminders, and mechanic notes from this device.")
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let data = car.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(colors: [.accentColor.opacity(0.34), .primary.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay {
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 84, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                        }
                }
            }
            .frame(height: 380)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.12), .black.opacity(0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(car.displayName)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 3)

                HStack(spacing: 10) {
                    Button {
                        beginEditingMileage()
                    } label: {
                        HStack(spacing: 8) {
                            Text("\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)")
                                .font(.headline)
                            Image(systemName: "pencil.circle.fill")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit current mileage")

                    Label(car.engineType.title, systemImage: car.engineType.symbolName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .accessibilityLabel("Engine type \(car.engineType.title)")
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Edit Photo", systemImage: "photo.badge.plus")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .accessibilityLabel("Edit car photo")
        }
    }

    private var mileageEditor: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Current mileage", text: $mileageDraft)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Current mileage")

                    Text(car.mileageUnit)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Mileage")
                } footer: {
                    if let mileageValidationMessage {
                        Text(mileageValidationMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text("Update the current mileage shown throughout MyGarageMate.")
                    }
                }
            }
            .navigationTitle("Edit Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditingMileage = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMileage()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            Button {
                HapticsManager.lightTap()
                isShowingThisYearServices = true
            } label: {
                summaryCard(
                    title: "This year",
                    value: CurrencyFormatter.string(fromMinor: car.totalSpentThisYear(currencyCode: profile.preferredCurrencyCode), currencyCode: profile.preferredCurrencyCode),
                    symbol: "creditcard.fill"
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show paid services this year")

            summaryCard(
                title: "Last service",
                value: car.lastService?.title ?? "None",
                subtitle: car.lastService?.date.formatted(date: .abbreviated, time: .omitted),
                symbol: "wrench.and.screwdriver.fill"
            )

            summaryCard(
                title: "Next reminder",
                value: car.nextImportantReminder?.title ?? "All clear",
                symbol: car.nextImportantReminder?.reminderType.symbolName ?? "checkmark.seal.fill"
            )

            summaryCard(
                title: "Records",
                value: "\(car.serviceRecords.count)",
                symbol: "list.bullet.rectangle.fill"
            )
        }
    }

    private var paidServicesThisYear: [ServiceRecord] {
        car.serviceRecords
            .filter { record in
                record.amountMinor > 0 &&
                Calendar.current.isDate(record.date, equalTo: .now, toGranularity: .year)
            }
            .sorted { $0.date > $1.date }
    }

    private func summaryCard(title: String, value: String, subtitle: String? = nil, symbol: String) -> some View {
        GlassCardView(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(.tint)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            overview
        case .history:
            ServiceHistoryView(car: car)
        case .notes:
            MechanicNotesView(car: car)
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                quickAction(title: "Add Service", symbol: "wrench.and.screwdriver.fill") {
                    isAddingService = true
                }
                quickAction(title: "Add Note", symbol: "note.text.badge.plus") {
                    isAddingNote = true
                }
                quickAction(title: "Add Reminder", symbol: "bell.badge.fill") {
                    isAddingReminder = true
                }
            }

            if car.upcomingReminders.isEmpty {
                EmptyStateView(
                    symbolName: "calendar.badge.checkmark",
                    title: "No upcoming reminders",
                    message: "Add one for oil, inspection, insurance, tires, or anything custom."
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Upcoming")
                        .font(.headline)
                    ForEach(car.upcomingReminders, id: \.id) { reminder in
                        ReminderRow(reminder: reminder, car: car)
                    }
                }
            }
        }
    }

    private func quickAction(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title3)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .accessibilityLabel(title)
    }

    private func beginEditingMileage() {
        mileageDraft = "\(Int(car.currentMileage.rounded()))"
        mileageValidationMessage = nil
        HapticsManager.lightTap()
        isEditingMileage = true
    }

    private func saveMileage() {
        let normalizedValue = mileageDraft
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        guard let mileage = Double(normalizedValue), mileage >= 0 else {
            mileageValidationMessage = "Enter a valid mileage."
            HapticsManager.warning()
            return
        }

        car.currentMileage = mileage

        do {
            try modelContext.save()
            HapticsManager.success()
            isEditingMileage = false
        } catch {
            mileageValidationMessage = "Could not save mileage. Try again."
            assertionFailure("Failed to update mileage: \(error)")
        }
    }

    private func generateServiceReport() {
        isGeneratingServiceReport = true
        serviceReportURL = nil
        serviceReportMessage = nil

        do {
            let url = try ServiceReportExporter.makePDF(for: car)
            serviceReportURL = url
            isShowingServiceReportShareSheet = true
            HapticsManager.success()
        } catch {
            serviceReportMessage = error.localizedDescription
            HapticsManager.warning()
        }

        isGeneratingServiceReport = false
    }

    private func updatePhoto(from item: PhotosPickerItem?) async {
        guard
            let data = try? await item?.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let jpegData = image.jpegData(compressionQuality: 0.82)
        else { return }

        await MainActor.run {
            car.photoData = jpegData

            do {
                try modelContext.save()
                HapticsManager.success()
            } catch {
                assertionFailure("Failed to update car photo: \(error)")
            }
        }
    }

    private func deleteCar() {
        for reminder in car.reminders {
            NotificationManager.cancel(reminder: reminder)
        }
        modelContext.delete(car)

        do {
            try modelContext.save()
            HapticsManager.warning()
            dismiss()
        } catch {
            assertionFailure("Failed to delete car: \(error)")
        }
    }
}

private struct ServiceReportShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

private enum DetailSection: String, CaseIterable, Identifiable {
    case overview
    case history
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .history: "History"
        case .notes: "Notes"
        }
    }
}

private struct ThisYearServicesView: View {
    @Environment(\.dismiss) private var dismiss
    let car: Car
    let records: [ServiceRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyStateView(
                        symbolName: "creditcard",
                        title: "No paid services this year",
                        message: "Paid services for \(car.make) \(car.model) will appear here."
                    )
                    .padding()
                } else {
                    List {
                        ForEach(records, id: \.id) { record in
                            HStack(spacing: 12) {
                                Image(systemName: record.category.symbolName)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.tint)
                                    .frame(width: 38, height: 38)
                                    .background(.thinMaterial, in: Circle())
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                CurrencyAmountView(amountMinor: record.amountMinor, currencyCode: record.currencyCode)
                            }
                            .padding(.vertical, 6)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("This Year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
