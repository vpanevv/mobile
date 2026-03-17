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
    var photoData: Data?
    var email: String?
    var age: Int?
    var appleUserID: String?

    init(
        name: String,
        createdAt: Date = .now,
        photoData: Data? = nil,
        email: String? = nil,
        age: Int? = nil,
        appleUserID: String? = nil
    ) {
        self.name = name
        self.createdAt = createdAt
        self.photoData = photoData
        self.email = email
        self.age = age
        self.appleUserID = appleUserID
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

private struct StoredUserAccount: Codable, Identifiable {
    let id: String
    var email: String
    var username: String
    var age: Int
    var createdAt: Date
    var photoData: Data?
}

private struct StoredAppState: Codable {
    var currentUserID: String?
    var accounts: [StoredUserAccount]
    var tasksByUserID: [String: [TodoTask]]

    init(
        currentUserID: String? = nil,
        accounts: [StoredUserAccount] = [],
        tasksByUserID: [String: [TodoTask]] = [:]
    ) {
        self.currentUserID = currentUserID
        self.accounts = accounts
        self.tasksByUserID = tasksByUserID
    }

    private enum CodingKeys: String, CodingKey {
        case currentUserID
        case accounts
        case tasksByUserID
        case profile
        case tasks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.accounts) || container.contains(.tasksByUserID) {
            let currentUserID = try container.decodeIfPresent(String.self, forKey: .currentUserID)
            let accounts = try container.decodeIfPresent([StoredUserAccount].self, forKey: .accounts) ?? []
            let tasksByUserID = try container.decodeIfPresent([String: [TodoTask]].self, forKey: .tasksByUserID) ?? [:]
            self.init(currentUserID: currentUserID, accounts: accounts, tasksByUserID: tasksByUserID)
            return
        }

        let legacyProfile = try container.decodeIfPresent(UserProfile.self, forKey: .profile)
        let legacyTasks = try container.decodeIfPresent([TodoTask].self, forKey: .tasks) ?? []

        guard let legacyProfile else {
            self.init()
            return
        }

        let legacyUserID = legacyProfile.appleUserID ?? "legacy-user"
        self.init(
            currentUserID: legacyUserID,
            accounts: [
                StoredUserAccount(
                    id: legacyUserID,
                    email: legacyProfile.email ?? "",
                    username: legacyProfile.name,
                    age: legacyProfile.age ?? 18,
                    createdAt: legacyProfile.createdAt,
                    photoData: legacyProfile.photoData
                )
            ],
            tasksByUserID: [legacyUserID: legacyTasks]
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(currentUserID, forKey: .currentUserID)
        try container.encode(accounts, forKey: .accounts)
        try container.encode(tasksByUserID, forKey: .tasksByUserID)
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var tasks: [TodoTask] = []

    private let persistenceURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var currentUserID: String?
    private var accounts: [StoredUserAccount] = []
    private var tasksByUserID: [String: [TodoTask]] = [:]

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

    var isAuthenticated: Bool {
        profile != nil
    }

    func saveProfile(name: String, photoData: Data? = nil) {
        guard let currentUserID, let index = accounts.firstIndex(where: { $0.id == currentUserID }) else { return }

        let existing = accounts[index]
        accounts[index].username = name
        accounts[index].photoData = photoData ?? existing.photoData
        syncCurrentUser()
        persist()
    }

    func updateProfile(name: String, photoData: Data?) {
        guard let currentUserID, let index = accounts.firstIndex(where: { $0.id == currentUserID }) else { return }

        accounts[index].username = name
        accounts[index].photoData = photoData
        syncCurrentUser()
        persist()
    }

    func signInWithApple(userID: String, email: String?) -> Bool {
        guard let index = accounts.firstIndex(where: { $0.id == userID }) else {
            return false
        }

        if let email, !email.isEmpty {
            accounts[index].email = email
        }

        currentUserID = userID
        syncCurrentUser()
        persist()
        return true
    }

    func registerAppleAccount(appleUserID: String, email: String, username: String, age: Int) throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            throw AuthError.invalidUsername
        }

        guard age >= 13 else {
            throw AuthError.invalidAge
        }

        if let existingIndex = accounts.firstIndex(where: { $0.id == appleUserID }) {
            accounts[existingIndex].email = email
            accounts[existingIndex].username = trimmedUsername
            accounts[existingIndex].age = age
        } else {
            guard !accounts.contains(where: { $0.username.caseInsensitiveCompare(trimmedUsername) == .orderedSame }) else {
                throw AuthError.usernameAlreadyTaken
            }

            accounts.append(
                StoredUserAccount(
                    id: appleUserID,
                    email: email,
                    username: trimmedUsername,
                    age: age,
                    createdAt: .now,
                    photoData: nil
                )
            )
        }

        currentUserID = appleUserID
        if tasksByUserID[appleUserID] == nil {
            tasksByUserID[appleUserID] = []
        }

        syncCurrentUser()
        persist()
    }

    func signIn(username: String) -> Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let account = accounts.first(where: { $0.username.caseInsensitiveCompare(trimmedUsername) == .orderedSame }) else {
            return false
        }

        currentUserID = account.id
        syncCurrentUser()
        persist()
        return true
    }

    func signOut() {
        currentUserID = nil
        profile = nil
        tasks = []
        persist()
    }

    func addTask(title: String, priority: TaskPriority, source: TaskSource, scheduledDay: Date) {
        guard currentUserID != nil else { return }
        let task = TodoTask(title: title, priority: priority, source: source, scheduledDay: scheduledDay)
        tasks.insert(task, at: 0)
        syncTaskState()
        persist()
    }

    func toggleCompletion(for taskID: UUID) {
        guard currentUserID != nil, let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].completedAt = tasks[index].completedAt == nil ? .now : nil
        syncTaskState()
        persist()
    }

    func deleteTask(id: UUID) {
        guard currentUserID != nil else { return }
        tasks.removeAll { $0.id == id }
        syncTaskState()
        persist()
    }

    func deleteCompletedTasks() {
        guard currentUserID != nil else { return }
        tasks.removeAll(where: { $0.isCompleted })
        syncTaskState()
        persist()
    }

    private func load() {
        do {
            let folderURL = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

            guard FileManager.default.fileExists(atPath: persistenceURL.path) else { return }
            let data = try Data(contentsOf: persistenceURL)
            let stored = try decoder.decode(StoredAppState.self, from: data)

            self.currentUserID = stored.currentUserID
            self.accounts = stored.accounts
            self.tasksByUserID = stored.tasksByUserID
            syncCurrentUser()
        } catch {
            self.currentUserID = nil
            self.accounts = []
            self.tasksByUserID = [:]
            self.profile = nil
            self.tasks = []
        }
    }

    private func persist() {
        do {
            let folderURL = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let stored = StoredAppState(currentUserID: currentUserID, accounts: accounts, tasksByUserID: tasksByUserID)
            let data = try encoder.encode(stored)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            assertionFailure("Failed to persist app state: \(error)")
        }
    }

    private func syncCurrentUser() {
        guard let currentUserID, let account = accounts.first(where: { $0.id == currentUserID }) else {
            profile = nil
            tasks = []
            return
        }

        profile = UserProfile(
            name: account.username,
            createdAt: account.createdAt,
            photoData: account.photoData,
            email: account.email.isEmpty ? nil : account.email,
            age: account.age,
            appleUserID: account.id
        )
        tasks = tasksByUserID[currentUserID] ?? []
    }

    private func syncTaskState() {
        guard let currentUserID else { return }
        tasksByUserID[currentUserID] = tasks
    }
}

extension AppStore {
    enum AuthError: LocalizedError {
        case invalidUsername
        case invalidAge
        case usernameAlreadyTaken

        var errorDescription: String? {
            switch self {
            case .invalidUsername:
                return "Enter a valid username."
            case .invalidAge:
                return "Enter an age of 13 or older."
            case .usernameAlreadyTaken:
                return "That username is already in use."
            }
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
