import Foundation
import SwiftUI
import Combine

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case high
    case important
    case quick
    case steady

    var id: String { rawValue }

    var title: String {
        switch self {
        case .high:
            "High"
        case .important:
            "Important"
        case .quick:
            "Quick"
        case .steady:
            "Steady"
        }
    }

    var symbolName: String {
        switch self {
        case .high:
            "flame.fill"
        case .important:
            "star.fill"
        case .quick:
            "bolt.fill"
        case .steady:
            "circle.grid.2x2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .high:
            .red
        case .important:
            .orange
        case .quick:
            .blue
        case .steady:
            .mint
        }
    }

    var rank: Int {
        switch self {
        case .high:
            0
        case .important:
            1
        case .quick:
            2
        case .steady:
            3
        }
    }
}

enum TaskSource: String, Codable {
    case manual
    case ai
}

struct UserProfile: Codable, Equatable {
    var name: String
    var createdAt: Date

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

struct TodoTask: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var priorityRawValue: String
    var sourceRawValue: String
    var scheduledDay: Date
    var createdAt: Date
    var completedAt: Date?

    init(
        title: String,
        priority: TaskPriority,
        source: TaskSource = .manual,
        scheduledDay: Date,
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.priorityRawValue = priority.rawValue
        self.sourceRawValue = source.rawValue
        self.scheduledDay = Calendar.autoupdatingCurrent.startOfDay(for: scheduledDay)
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .important }
        set { priorityRawValue = newValue.rawValue }
    }

    var source: TaskSource {
        get { TaskSource(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }

    var isCompleted: Bool {
        completedAt != nil
    }
}

private struct StoredAppState: Codable {
    var profile: UserProfile?
    var tasks: [TodoTask]
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var tasks: [TodoTask] = []

    private let persistenceURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = appSupport.appendingPathComponent("ToDoAI", isDirectory: true)
        self.persistenceURL = folderURL.appendingPathComponent("state.json")

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601

        load()
    }

    func saveProfile(name: String) {
        profile = UserProfile(name: name)
        persist()
    }

    func addTask(title: String, priority: TaskPriority, source: TaskSource, scheduledDay: Date) {
        let task = TodoTask(title: title, priority: priority, source: source, scheduledDay: scheduledDay)
        tasks.insert(task, at: 0)
        persist()
    }

    func toggleCompletion(for taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].completedAt = tasks[index].completedAt == nil ? .now : nil
        persist()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    func deleteCompletedTasks() {
        tasks.removeAll(where: { $0.isCompleted })
        persist()
    }

    private func load() {
        do {
            let folderURL = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

            guard FileManager.default.fileExists(atPath: persistenceURL.path) else { return }
            let data = try Data(contentsOf: persistenceURL)
            let stored = try decoder.decode(StoredAppState.self, from: data)
            self.profile = stored.profile
            self.tasks = stored.tasks
        } catch {
            self.profile = nil
            self.tasks = []
        }
    }

    private func persist() {
        do {
            let folderURL = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let stored = StoredAppState(profile: profile, tasks: tasks)
            let data = try encoder.encode(stored)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            assertionFailure("Failed to persist app state: \(error)")
        }
    }
}

extension Array where Element == TodoTask {
    func sortedForDashboard() -> [TodoTask] {
        sorted {
            if $0.priority.rank != $1.priority.rank {
                return $0.priority.rank < $1.priority.rank
            }

            if $0.scheduledDay != $1.scheduledDay {
                return $0.scheduledDay > $1.scheduledDay
            }

            return $0.createdAt > $1.createdAt
        }
    }
}
