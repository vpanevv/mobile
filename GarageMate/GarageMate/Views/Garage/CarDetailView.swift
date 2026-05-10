import SwiftUI
import UIKit

struct CarDetailView: View {
    @Bindable var car: Car
    let profile: UserProfile

    @State private var selectedSection: DetailSection = .overview
    @State private var isAddingService = false
    @State private var isAddingNote = false
    @State private var isAddingReminder = false

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
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add item")
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
            .frame(height: 310)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(car.displayName)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                Text("\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
        }
        .accessibilityElement(children: .combine)
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(
                title: "This year",
                value: CurrencyFormatter.string(fromMinor: car.totalSpentThisYear(currencyCode: profile.preferredCurrencyCode), currencyCode: profile.preferredCurrencyCode),
                symbol: "creditcard.fill"
            )

            summaryCard(
                title: "Last service",
                value: car.lastService?.date.formatted(date: .abbreviated, time: .omitted) ?? "None",
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

    private func summaryCard(title: String, value: String, symbol: String) -> some View {
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
                quickAction(title: "Service", symbol: "wrench.and.screwdriver.fill") {
                    isAddingService = true
                }
                quickAction(title: "Note", symbol: "note.text.badge.plus") {
                    isAddingNote = true
                }
                quickAction(title: "Reminder", symbol: "bell.badge.fill") {
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
                    ForEach(car.upcomingReminders) { reminder in
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
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 16))
    }
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
