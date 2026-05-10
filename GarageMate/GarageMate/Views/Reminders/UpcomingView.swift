import SwiftData
import SwiftUI

struct UpcomingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Car.createdAt, order: .forward) private var cars: [Car]

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
                                        HapticsManager.success()
                                    } label: {
                                        Label("Complete", systemImage: "checkmark")
                                    }
                                    .tint(.green)

                                    Button(role: .destructive) {
                                        NotificationManager.cancel(reminder: item.reminder)
                                        modelContext.delete(item.reminder)
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
        }
    }
}
