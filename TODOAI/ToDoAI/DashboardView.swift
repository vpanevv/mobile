import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showingTaskComposer = false
    @State private var showingAIAssist = false
    @State private var pendingDeleteTask: TodoTask?

    let profile: UserProfile

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                heroCard
                actionsRow
                taskSection(title: "Today", tasks: todayOpenTasks, emptyMessage: "No active tasks yet. Add one to shape your day.")

                if !yesterdayCarryOverTasks.isEmpty {
                    taskSection(
                        title: "From Yesterday",
                        tasks: yesterdayCarryOverTasks,
                        emptyMessage: ""
                    )
                }

                summaryCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 36)
        }
        .sheet(isPresented: $showingTaskComposer) {
            TaskComposerSheet(onCreate: createTask)
        }
        .sheet(isPresented: $showingAIAssist) {
            AIAssistSheet(userName: profile.name, onAdd: addSuggestedTasks)
        }
        .confirmationDialog(
            "Delete task?",
            isPresented: Binding(
                get: { pendingDeleteTask != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeleteTask = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let task = pendingDeleteTask {
                    store.deleteTask(id: task.id)
                }
                pendingDeleteTask = nil
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteTask = nil
            }
        } message: {
            if let task = pendingDeleteTask {
                Text("Delete \"\(task.title)\" from your plan?")
            }
        }
    }

    private var heroCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(greetingText(for: context.date))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(context.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.82))
                        }

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.yellow)
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.white.opacity(0.82))

                        Text(context.date.formatted(.dateTime.hour().minute().second()))
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 12) {
                        statPill(title: "Open", value: "\(todayOpenTasks.count)", tint: .cyan, symbol: "waveform.path.ecg")
                        statPill(title: "Carry-over", value: "\(yesterdayCarryOverTasks.count)", tint: .orange, symbol: "arrow.trianglehead.clockwise")
                        statPill(title: "Done today", value: "\(completedTodayTasks.count)", tint: .green, symbol: "checkmark.seal.fill")
                    }
                }
            }
        }
    }

    private var actionsRow: some View {
        HStack(spacing: 14) {
            actionButton(title: "New Task", systemName: "plus") {
                showingTaskComposer = true
            }

            actionButton(title: "AI Assist", systemName: "sparkles", isPrimaryAI: true) {
                showingAIAssist = true
            }
        }
    }

    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Daily Summary")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(summaryHeadline)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))

                if completedTodayTasks.isEmpty {
                    Text("Finish a task and the summary will build itself here.")
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    ForEach(completedTodayTasks) { task in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .foregroundStyle(.white)

                                Text("Completed \(task.completedAt?.formatted(date: .omitted, time: .shortened) ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.68))
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func taskSection(title: String, tasks: [TodoTask], emptyMessage: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                if tasks.isEmpty {
                    Text(emptyMessage)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    ForEach(tasks) { task in
                        TaskRow(
                            task: task,
                            onToggle: {
                                toggleCompletion(for: task)
                            },
                            onRequestDelete: {
                                pendingDeleteTask = task
                            }
                        )
                    }
                }
            }
        }
    }

    private func statPill(title: String, value: String, tint: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)

                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.74))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [
                    tint.opacity(0.22),
                    Color.white.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        }
    }

    private func actionButton(
        title: String,
        systemName: String,
        isPrimaryAI: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Group {
            if isPrimaryAI {
                Button(action: action) {
                    Label(title, systemImage: systemName)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
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
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.42), lineWidth: 1)
                }
                .shadow(color: Color.yellow.opacity(0.35), radius: 18, y: 8)
            } else {
                Button(action: action) {
                    Label(title, systemImage: systemName)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
            }
        }
    }

    private var todayOpenTasks: [TodoTask] {
        store.tasks
            .filter { calendar.isDate($0.scheduledDay, inSameDayAs: todayStart) && !$0.isCompleted }
            .sortedForDashboard()
    }

    private var yesterdayCarryOverTasks: [TodoTask] {
        store.tasks
            .filter { calendar.isDate($0.scheduledDay, inSameDayAs: yesterdayStart) && !$0.isCompleted }
            .sortedForDashboard()
    }

    private var completedTodayTasks: [TodoTask] {
        store.tasks
            .filter {
                guard let completedAt = $0.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: todayStart)
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var todayStart: Date {
        calendar.startOfDay(for: .now)
    }

    private var yesterdayStart: Date {
        calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
    }

    private var summaryHeadline: String {
        if completedTodayTasks.isEmpty {
            return "Nothing completed yet today."
        }

        if completedTodayTasks.count == 1 {
            return "You completed 1 task today."
        }

        return "You completed \(completedTodayTasks.count) tasks today."
    }

    private func createTask(title: String, priority: TaskPriority) {
        store.addTask(title: title, priority: priority, source: .manual, scheduledDay: todayStart)
    }

    private func addSuggestedTasks(_ suggestions: [AISuggestedTask]) {
        for suggestion in suggestions {
            store.addTask(
                title: suggestion.title,
                priority: suggestion.priority,
                source: .ai,
                scheduledDay: todayStart
            )
        }
    }

    private func toggleCompletion(for task: TodoTask) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            store.toggleCompletion(for: task.id)
        }
    }

    private func greetingText(for date: Date) -> String {
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<12:
            return "Good morning \(profile.name), ready for the day?"
        case 12..<18:
            return "Good afternoon \(profile.name)"
        default:
            return "Good evening \(profile.name)"
        }
    }
}

private struct TaskRow: View {
    let task: TodoTask
    let onToggle: () -> Void
    let onRequestDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(task.isCompleted ? .green : .white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(task.isCompleted ? 0.18 : 0.08), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .strikethrough(task.isCompleted, color: .white.opacity(0.8))

                HStack(spacing: 8) {
                    PriorityBadge(priority: task.priority)

                    if task.source == .ai {
                        Label("AI", systemImage: "sparkles")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(.yellow)
                            .background(Color.yellow.opacity(0.12), in: Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onRequestDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
