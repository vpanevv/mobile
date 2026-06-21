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
    @State private var isPhotoPickerPresented = false
    @State private var isEditingMileage = false
    @State private var mileageDraft = ""
    @State private var mileageValidationMessage: String?
    @State private var serviceReportURL: URL?
    @State private var serviceReportMessage: String?
    @State private var isGeneratingServiceReport = false
    @State private var isShowingServiceReportShareSheet = false
    @State private var isShowingThisYearServices = false
    @State private var liveActivityActive = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                hero

                summaryCards
                    .padding(.horizontal)

                GlassSegmentedControl(
                    items: DetailSection.allCases,
                    title: { $0.title },
                    selection: $selectedSection
                )
                .padding(.horizontal)

                sectionContent
                    .padding(.horizontal)
                    .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .coordinateSpace(name: "carDetailScroll")
        .ignoresSafeArea(edges: .top)
        .scrollContentBackground(.hidden)
        .background(AmbientBackground(tint: car.healthStatus.tint))
        .navigationTitle(car.model)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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

                Divider()

                Button {
                    isPhotoPickerPresented = true
                } label: {
                    Label(car.photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo.badge.plus")
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
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedPhotoItem, matching: .images)
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

    private let heroBaseHeight: CGFloat = 440

    private var hero: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("carDetailScroll")).minY
            let stretch = max(0, minY)
            let height = heroBaseHeight + stretch

            ZStack(alignment: .bottomLeading) {
                heroImage
                    .frame(width: geo.size.width, height: height)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.15), .black.opacity(0.62)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 240)
                    }

                heroOverlay
            }
            .frame(width: geo.size.width, height: height)
            .offset(y: -stretch)
        }
        .frame(height: heroBaseHeight)
    }

    private var heroImage: some View {
        Group {
            if let data = car.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Theme.accent, Theme.mist, Theme.accent.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 150, weight: .bold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.white.opacity(0.22))
                        .offset(y: -30)
                }
            }
        }
    }

    private var heroOverlay: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(car.displayName)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 3)

            ScrollView(.horizontal) {
                HStack(spacing: Theme.Spacing.s) {
                    Button {
                        beginEditingMileage()
                    } label: {
                        GlassChip(
                            systemImage: "gauge.with.dots.needle.67percent",
                            text: "\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)",
                            tint: .white
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit current mileage")

                    GlassChip(systemImage: car.engineType.symbolName, text: car.engineType.title, tint: .white)
                        .accessibilityLabel("Engine type \(car.engineType.title)")

                    StatusBadge(status: car.healthStatus)
                        .accessibilityLabel("Car status \(car.healthStatus.title)")
                }
                .padding(.bottom, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.m), GridItem(.flexible())], spacing: Theme.Spacing.m) {
            Button {
                HapticsManager.lightTap()
                isShowingThisYearServices = true
            } label: {
                summaryCard(
                    title: "This year",
                    value: CurrencyFormatter.string(fromMinor: car.totalSpentThisYear(currencyCode: profile.preferredCurrencyCode), currencyCode: profile.preferredCurrencyCode),
                    symbol: "creditcard.fill",
                    tint: Theme.highlight
                )
            }
            .buttonStyle(CardPressStyle())
            .accessibilityLabel("Show paid services this year")

            summaryCard(
                title: "Last service",
                value: car.lastService?.title ?? "None",
                subtitle: car.lastService?.date.formatted(date: .abbreviated, time: .omitted),
                symbol: "wrench.and.screwdriver.fill",
                tint: Theme.accent
            )

            summaryCard(
                title: "Next reminder",
                value: car.nextImportantReminder?.title ?? "All clear",
                symbol: car.nextImportantReminder?.reminderType.symbolName ?? "checkmark.seal.fill",
                tint: car.healthStatus.tint
            )

            summaryCard(
                title: "Records",
                value: "\(car.serviceRecords.count)",
                symbol: "list.bullet.rectangle.fill",
                tint: Theme.mist
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

    private func summaryCard(title: String, value: String, subtitle: String? = nil, symbol: String, tint: Color = Theme.accent) -> some View {
        GlassCard(cornerRadius: Theme.Radius.card) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Image(systemName: symbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            // Fixed height keeps all four tiles identical regardless of content length.
            .frame(maxWidth: .infinity, minHeight: 132, maxHeight: 132, alignment: .topLeading)
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
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
            HStack(spacing: Theme.Spacing.m) {
                quickAction(title: "Add Service", symbol: "wrench.and.screwdriver.fill", tint: Theme.accent) {
                    isAddingService = true
                }
                quickAction(title: "Add Note", symbol: "note.text.badge.plus", tint: Theme.ember) {
                    isAddingNote = true
                }
                quickAction(title: "Add Reminder", symbol: "bell.badge.fill", tint: Theme.mist) {
                    isAddingReminder = true
                }
            }

            if car.nextImportantReminder != nil {
                liveActivityButton
            }

            SpendInsightsView(car: car, currencyCode: profile.preferredCurrencyCode)

            MileageTrendCard(car: car)

            if car.upcomingReminders.isEmpty {
                EmptyStateView(
                    symbolName: "calendar.badge.checkmark",
                    title: "No upcoming reminders",
                    message: "Add one for oil, inspection, insurance, tires, or anything custom."
                )
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    SectionHeader("Upcoming", systemImage: "calendar.badge.clock")
                    ForEach(car.upcomingReminders, id: \.id) { reminder in
                        ReminderRow(reminder: reminder, car: car)
                    }
                }
            }
        }
    }

    private var liveActivityButton: some View {
        Button {
            toggleLiveActivity()
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: liveActivityActive ? "bolt.badge.checkmark.fill" : "bolt.badge.clock.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background((liveActivityActive ? Theme.highlight : Theme.accent).gradient, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(liveActivityActive ? "Tracking on Lock Screen" : "Track on Lock Screen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(liveActivityActive ? "Tap to stop the Live Activity" : "Live countdown to your next service")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: liveActivityActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .padding(Theme.Spacing.l)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .onAppear { liveActivityActive = ServiceActivityManager.hasActive }
        .accessibilityLabel(liveActivityActive ? "Stop Lock Screen tracking" : "Track next service on Lock Screen")
    }

    private func toggleLiveActivity() {
        if liveActivityActive {
            ServiceActivityManager.end()
            liveActivityActive = false
            HapticsManager.soft()
            return
        }

        guard let reminder = car.nextImportantReminder else { return }
        let started = ServiceActivityManager.start(
            carName: car.model,
            reminderTitle: reminder.title,
            symbolName: reminder.reminderType.symbolName,
            statusRawValue: car.healthStatus.rawValue,
            dueDate: reminder.dueDate
        )
        liveActivityActive = started
        if started {
            HapticsManager.success()
        } else {
            HapticsManager.warning()
        }
    }

    private func quickAction(title: String, symbol: String, tint: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.soft()
            action()
        } label: {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.l)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
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
