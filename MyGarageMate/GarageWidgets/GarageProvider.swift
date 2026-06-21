import SwiftUI
import WidgetKit

struct GarageEntry: TimelineEntry {
    let date: Date
    let snapshot: GarageSnapshot
}

struct GarageProvider: TimelineProvider {
    func placeholder(in context: Context) -> GarageEntry {
        GarageEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GarageEntry) -> Void) {
        completion(GarageEntry(date: .now, snapshot: GarageSharedData.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GarageEntry>) -> Void) {
        let entry = GarageEntry(date: .now, snapshot: GarageSharedData.load() ?? .placeholder)
        // The app pushes fresh data on changes; this is a periodic safety refresh.
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21_600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

extension Color {
    init(sharedStatus rawValue: String) {
        let c = SharedStatusStyle.color(for: rawValue)
        self.init(red: c.r, green: c.g, blue: c.b)
    }
}
