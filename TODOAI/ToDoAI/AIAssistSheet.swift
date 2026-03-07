import SwiftUI

struct AISuggestedTask: Identifiable {
    let id = UUID()
    let title: String
    let priority: TaskPriority
}

enum AIPlanner {
    static func suggestions(for focus: String, userName: String, now: Date = .now) -> [AISuggestedTask] {
        let cleaned = focus
            .replacingOccurrences(of: "\n", with: ",")
            .replacingOccurrences(of: " and ", with: ",")

        let fragments = cleaned
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var suggestions: [AISuggestedTask] = []

        for (index, fragment) in fragments.prefix(3).enumerated() {
            let priority = [TaskPriority.high, .important, .quick][min(index, 2)]
            let normalized = fragment.prefix(1).uppercased() + fragment.dropFirst()
            suggestions.append(AISuggestedTask(title: normalized, priority: priority))

            if priority == .high {
                suggestions.append(
                    AISuggestedTask(
                        title: "Finish the most important part of \(fragment.lowercased())",
                        priority: .important
                    )
                )
            }
        }

        if suggestions.isEmpty {
            let hour = Calendar.autoupdatingCurrent.component(.hour, from: now)
            let warmupTitle = hour < 12 ? "Set the top 3 wins for the morning" : "Reset the plan for the rest of the day"

            suggestions = [
                AISuggestedTask(title: "\(warmupTitle), \(userName)", priority: .high),
                AISuggestedTask(title: "Clear one small task in under 10 minutes", priority: .quick),
                AISuggestedTask(title: "Review progress before the day ends", priority: .important),
            ]
        }

        var uniqueTitles = Set<String>()
        return suggestions.filter { uniqueTitles.insert($0.title).inserted }
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
                        LiveClockHeader()

                        Spacer(minLength: suggestions.isEmpty ? 0 : 8)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("AI Task Assist")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .multilineTextAlignment(.center)

                                Text("Describe your day or goal, and ToDoAI will break it into tasks for today.")
                                    .foregroundStyle(.white.opacity(0.78))
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
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.24),
                                            Color.cyan.opacity(0.18),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                                }
                                .foregroundStyle(.white)

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
                                            Color.yellow,
                                            Color(red: 1.0, green: 0.79, blue: 0.24),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.38), lineWidth: 1)
                                }
                                .shadow(color: Color.yellow.opacity(0.30), radius: 18, y: 8)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan.opacity(0.18),
                                            Color.blue.opacity(0.14),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                        if !suggestions.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Suggested tasks")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)

                                    ForEach(suggestions) { suggestion in
                                        HStack(alignment: .top, spacing: 12) {
                                            Image(systemName: "sparkles")
                                                .foregroundStyle(.yellow)

                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(suggestion.title)
                                                    .font(.body.weight(.medium))
                                                    .foregroundStyle(.white)
                                                PriorityBadge(priority: suggestion.priority)
                                            }

                                            Spacer()
                                        }
                                    }
                                }
                            }

                            Button(action: addSuggestedTasks) {
                                Text("Add All for Today")
                                    .font(.headline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.black)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
}
