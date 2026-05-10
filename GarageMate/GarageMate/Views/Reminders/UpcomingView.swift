import SwiftData
import SwiftUI

struct UpcomingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Car.createdAt, order: .forward) private var cars: [Car]
    @State private var reminderPendingDeletion: CarReminder?

    private var reminders: [(reminder: CarReminder, car: Car)] {
        cars.flatMap { car in
            car.reminders
                .filter { !$0.isCompleted }
                .map { (reminder: $0, car: car) }
        }
        .sorted { lhs, rhs in
            CarReminder.sortUpcoming(lhs.reminder, rhs.reminder)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if reminders.isEmpty {
                    EmptyStateView(
                        symbolName: "calendar.badge.checkmark",
                        title: "Nothing due",
                        message: "Upcoming reminders from every car will appear here, sorted by date and mileage."
                    )
                    .padding(.horizontal)
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(reminders, id: \.reminder.id) { item in
                            ReminderRow(reminder: item.reminder, car: item.car)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        item.reminder.isCompleted = true
                                        NotificationManager.cancel(reminder: item.reminder)
                                        do {
                                            try modelContext.save()
                                            HapticsManager.success()
                                        } catch {
                                            assertionFailure("Failed to complete reminder: \(error)")
                                        }
                                    } label: {
                                        Label("Complete", systemImage: "checkmark")
                                    }
                                    .tint(.green)

                                    Button(role: .destructive) {
                                        reminderPendingDeletion = item.reminder
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Upcoming")
            .confirmationDialog(
                "Delete reminder?",
                isPresented: Binding(
                    get: { reminderPendingDeletion != nil },
                    set: { if !$0 { reminderPendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Reminder", role: .destructive) {
                    deletePendingReminder()
                }
                Button("Cancel", role: .cancel) {
                    reminderPendingDeletion = nil
                }
            } message: {
                Text("This removes the selected reminder and cancels its pending notification.")
            }
        }
    }

    private func deletePendingReminder() {
        guard let reminder = reminderPendingDeletion else { return }
        NotificationManager.cancel(reminder: reminder)
        modelContext.delete(reminder)
        do {
            try modelContext.save()
            HapticsManager.warning()
        } catch {
            assertionFailure("Failed to delete reminder: \(error)")
        }
        reminderPendingDeletion = nil
    }
}
