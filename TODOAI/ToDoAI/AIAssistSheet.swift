import SwiftUI

struct AISuggestedTask: Identifiable {
    let id = UUID()
    let title: String
    let priority: TaskPriority
}

enum AIPlanner {
    static func suggestions(for focus: String, userName: String, now: Date = .now) -> [AISuggestedTask] {
        let fragments = actionableFragments(from: focus)
        let tasks = fragments
            .compactMap(taskTitle(from:))
            .uniqued()

        if tasks.isEmpty {
            let hour = Calendar.autoupdatingCurrent.component(.hour, from: now)
            let warmupTitle = hour < 12 ? "Set the top 3 wins for the morning" : "Reset the plan for the rest of the day"

            return [
                AISuggestedTask(title: "\(warmupTitle), \(userName)", priority: .high),
                AISuggestedTask(title: "Clear one small task in under 10 minutes", priority: .quick),
                AISuggestedTask(title: "Review progress before the day ends", priority: .important),
            ]
        }

        return tasks.prefix(3).enumerated().map { index, task in
            AISuggestedTask(title: task, priority: [TaskPriority.high, .important, .quick][min(index, 2)])
        }
    }

    private static func actionableFragments(from focus: String) -> [String] {
        var text = focus.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let separators = ["\n", ",", ";", " then ", " after that ", " also ", " plus ", " and "]
        for separator in separators {
            text = text.replacingOccurrences(of: separator, with: "|")
        }

        return text
            .split(separator: "|")
            .map { sanitizeFragment(String($0)) }
            .filter { !$0.isEmpty }
    }

    private static func sanitizeFragment(_ fragment: String) -> String {
        var text = fragment.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

        let prefixes = [
            "today i have to ",
            "today i need to ",
            "today i want to ",
            "tonight i have to ",
            "tonight i need to ",
            "tonight i want to ",
            "i have to ",
            "i need to ",
            "i want to ",
            "i should ",
            "i must ",
            "help me ",
            "can you help me ",
            "please ",
        ]

        var removedPrefix = true
        while removedPrefix {
            removedPrefix = false
            for prefix in prefixes where text.hasPrefix(prefix) {
                text.removeFirst(prefix.count)
                text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                removedPrefix = true
            }
        }

        return text
    }

    private static func taskTitle(from fragment: String) -> String? {
        guard !fragment.isEmpty else { return nil }

        if let videoTask = videoTask(from: fragment) {
            return videoTask
        }

        if containsAny(["email", "emails", "message", "messages", "inbox"], in: fragment) {
            return "Reply to messages"
        }

        if containsAny(["workout", "exercise", "gym", "run"], in: fragment) {
            return "Do a workout"
        }

        if let task = taskWithPrefix("finish ", action: "Finish", in: fragment) {
            return task
        }

        if let task = taskWithPrefix("review ", action: "Review", in: fragment) {
            return task
        }

        if let task = taskWithPrefix("prepare ", action: "Prepare", in: fragment) {
            return task
        }

        if let task = taskWithPrefix("practice ", action: "Practice", in: fragment) {
            return task
        }

        if let task = taskWithPrefix("watch ", action: "Watch", in: fragment) {
            return task
        }

        return sentenceCase(fragment)
    }

    private static func videoTask(from fragment: String) -> String? {
        guard containsAny(["video", "videos", "film", "films", "highlights"], in: fragment) else { return nil }

        let target: String
        if let forRange = fragment.range(of: "for ") {
            target = cleanTarget(String(fragment[forRange.upperBound...]))
        } else if fragment.contains("volleyball") {
            target = "the volleyball game"
        } else {
            target = ""
        }

        if !target.isEmpty {
            return "Watch videos for \(target)"
        }

        return "Watch videos related to your plan"
    }

    private static func taskWithPrefix(_ prefix: String, action: String, in fragment: String) -> String? {
        guard fragment.hasPrefix(prefix) else { return nil }
        let target = cleanTarget(String(fragment.dropFirst(prefix.count)))
        guard !target.isEmpty else { return nil }
        return "\(action) \(target)"
    }

    private static func cleanTarget(_ target: String) -> String {
        var text = target.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

        let stopTokens = [" with ", " using ", " by ", " tonight", " today", " tomorrow"]
        for token in stopTokens {
            if let range = text.range(of: token) {
                text = String(text[..<range.lowerBound])
            }
        }

        return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func containsAny(_ values: [String], in text: String) -> Bool {
        values.contains { text.contains($0) }
    }

    private static func sentenceCase(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

struct AIAssistSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var focus = ""
    @State private var suggestions: [AISuggestedTask] = []

    let userName: String
    let onAdd: ([AISuggestedTask]) -> Void

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        sheetHeader

                        Spacer(minLength: suggestions.isEmpty ? 0 : 8)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("AI Task Assist")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.black.opacity(0.86))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)

                            Text("Describe your day or goal, and ToDoAI will break it into tasks for today.")
                                .foregroundStyle(Color.black.opacity(0.64))
                                .multilineTextAlignment(.center)

                            TextField(
                                "Example: finish the client proposal, answer messages, and go for a workout",
                                text: $focus,
                                axis: .vertical
                            )
                            .lineLimit(3...6)
                            .textInputAutocapitalization(.sentences)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            }
                            .foregroundStyle(Color.black.opacity(0.84))

                            Button(action: generateSuggestions) {
                                Label("Generate Suggestions", systemImage: "sparkles")
                                    .font(.headline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.black)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.86, green: 0.97, blue: 0.99),
                                        Color(red: 0.77, green: 0.93, blue: 1.0),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            }
                            .shadow(color: Color.cyan.opacity(0.18), radius: 16, y: 8)
                        }
                        .padding(22)
                        .background(sheetCardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                        }
                        .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)

                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Suggested tasks")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color.black.opacity(0.84))

                                ForEach(suggestions) { suggestion in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "sparkles")
                                            .foregroundStyle(.cyan)

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(suggestion.title)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(Color.black.opacity(0.84))
                                            PriorityBadge(priority: suggestion.priority)
                                        }

                                        Spacer()
                                    }
                                }
                            }
                            .padding(22)
                            .background(sheetCardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                            }
                            .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)

                            Button(action: addSuggestedTasks) {
                                Text("Add All for Today")
                                    .font(.headline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.black)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.86, green: 0.97, blue: 0.99),
                                        Color(red: 0.77, green: 0.93, blue: 1.0),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: proxy.size.height - 40)
                    .padding(20)
                }
            }
            .background(AppBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateSuggestions() {
        suggestions = AIPlanner.suggestions(for: focus, userName: userName)
    }

    private func addSuggestedTasks() {
        guard !suggestions.isEmpty else { return }
        onAdd(suggestions)
        dismiss()
    }

    private var sheetHeader: some View {
        VStack(spacing: 10) {
            Label("AI Planner", systemImage: "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.84))

            LiveClockHeader(style: .contrastOnLight)
        }
        .padding(22)
        .background(sheetCardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
        }
        .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)
    }

    private var sheetCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 1.0, blue: 1.0),
                            Color(red: 0.89, green: 0.97, blue: 0.99),
                            Color(red: 0.97, green: 0.98, blue: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .offset(x: -120, y: -90)

            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 22)
                .offset(x: 110, y: 80)
        }
    }
}
