import Foundation
import SwiftData
import WidgetKit

/// Builds a compact ``GarageSnapshot`` from SwiftData and publishes it to the
/// shared App Group container so the widget/Live Activity extension stays current.
enum GarageSnapshotWriter {
    @MainActor
    static func update(context: ModelContext, currencyCode: String) {
        let cars = (try? context.fetch(FetchDescriptor<Car>())) ?? []

        let carSnapshots = cars.map { car in
            CarSnapshot(
                id: car.id,
                name: car.model,
                statusRawValue: car.healthStatus.rawValue,
                spentThisYearMinor: car.totalSpentThisYear(currencyCode: currencyCode)
            )
        }

        let totalThisYear = carSnapshots.reduce(0) { $0 + $1.spentThisYearMinor }

        // The single most urgent upcoming reminder across the whole garage.
        let nextReminder: ReminderSnapshot? = cars
            .flatMap { car in car.upcomingReminders.map { (reminder: $0, car: car) } }
            .sorted { CarReminder.sortUpcoming($0.reminder, $1.reminder) }
            .first
            .map { pair in
                ReminderSnapshot(
                    id: pair.reminder.id,
                    title: pair.reminder.title,
                    carName: pair.car.model,
                    symbolName: pair.reminder.reminderType.symbolName,
                    dueDate: pair.reminder.dueDate,
                    dueMileage: pair.reminder.dueMileage,
                    mileageUnit: pair.car.mileageUnit,
                    statusRawValue: pair.car.healthStatus.rawValue
                )
            }

        let snapshot = GarageSnapshot(
            generatedAt: .now,
            currencyCode: currencyCode,
            totalSpentThisYearMinor: totalThisYear,
            carCount: cars.count,
            nextReminder: nextReminder,
            cars: carSnapshots
        )

        GarageSharedData.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
