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
                taskSection(
                    title: "Today",
                    tasks: todayOpenTasks,
                    emptyMessage: "No active tasks yet. Add one to shape your day."
                )

                if !yesterdayCarryOverTasks.isEmpty {
                    taskSection(
                        title: "From Yesterday",
                        tasks: yesterdayCarryOverTasks,
                        emptyMessage: "",
                        allowsDelete: true
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
                Text("Delete \"\(task.title)\" from yesterday's carry-over tasks?")
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

                    LiveClockHeader()

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
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Daily Summary", systemImage: completedTodayTasks.isEmpty ? "moon.stars.fill" : "sparkles")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.82))

                        Text(summaryHeadline)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.9))

                        Text(summarySupportText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.black.opacity(0.6))
                    }

                    Spacer()

                    summaryBadge
                }

                summaryProgressPanel

                if completedTodayTasks.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.title3)
                            .foregroundStyle(Color.orange.opacity(0.9))

                        Text("Your wins will light up here as soon as you complete the first task.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.black.opacity(0.65))
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        ForEach(completedTodayTasks) { task in
                            SummaryTaskRow(task: task)
                        }
                    }
                }
            }
            .padding(22)
            .background(summaryBackground(time: time))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.38), lineWidth: 1.2)
            }
            .shadow(color: Color.yellow.opacity(0.18), radius: 24, y: 12)
        }
    }

    private func taskSection(
        title: String,
        tasks: [TodoTask],
        emptyMessage: String,
        allowsDelete: Bool = false
    ) -> some View {
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
                            allowsDelete: allowsDelete,
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
            return "Your momentum starts here."
        }

        if completedTodayTasks.count == 1 {
            return "1 win already in the bank."
        }

        return "\(completedTodayTasks.count) wins completed today."
    }

    private var summarySupportText: String {
        if completedTodayTasks.isEmpty {
            return "Wrap up a task to unlock today's highlight reel."
        }

        if completionRatio >= 1 {
            return "You cleared every active task on the board today."
        }

        if completionRatio >= 0.6 {
            return "Strong pace. Your day is moving in the right direction."
        }

        return "Progress is building. Each finished task sharpens the day."
    }

    private var completedTaskCount: Int {
        completedTodayTasks.count
    }

    private var activeTodayTaskCount: Int {
        todayOpenTasks.count + completedTaskCount
    }

    private var completionRatio: Double {
        guard activeTodayTaskCount > 0 else { return 0 }
        return min(Double(completedTaskCount) / Double(activeTodayTaskCount), 1)
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
            return "Good morning, \(profile.name), ready for the day?"
        case 12..<18:
            return "Good afternoon, \(profile.name)"
        default:
            return "Good evening, \(profile.name)"
        }
    }

    private var summaryBadge: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(completedTaskCount.formatted())
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.88))

            Text(completedTaskCount == 1 ? "task done" : "tasks done")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.58))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var summaryProgressPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's rhythm")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.7))

                Spacer()

                Text(activeTodayTaskCount == 0 ? "No tasks yet" : "\(Int((completionRatio * 100).rounded()))% complete")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.58))
            }

            GeometryReader { proxy in
                let width = max(proxy.size.width * completionRatio, completionRatio > 0 ? 24 : 0)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.28))

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.95),
                                    Color.yellow.opacity(0.95),
                                    Color.white.opacity(0.95),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width)
                }
            }
            .frame(height: 18)

            HStack(spacing: 10) {
                summaryMetric(title: "Completed", value: "\(completedTaskCount)", symbol: "checkmark.seal.fill")
                summaryMetric(title: "Still open", value: "\(todayOpenTasks.count)", symbol: "bolt.fill")
                summaryMetric(title: "Carry-over", value: "\(yesterdayCarryOverTasks.count)", symbol: "arrow.uturn.forward.circle.fill")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.34), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func summaryMetric(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.callout.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.62))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.88))

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.56))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryBackground(time: TimeInterval) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.87, blue: 0.47),
                            Color(red: 1.0, green: 0.73, blue: 0.30),
                            Color(red: 1.0, green: 0.93, blue: 0.72),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.38))
                .frame(width: 180, height: 180)
                .blur(radius: 12)
                .offset(x: -110 + cos(time * 0.42) * 14, y: -90 + sin(time * 0.35) * 10)

            Circle()
                .fill(Color.orange.opacity(0.25))
                .frame(width: 220, height: 220)
                .blur(radius: 20)
                .offset(x: 120 + sin(time * 0.28) * 16, y: 110 + cos(time * 0.22) * 14)
        }
    }
}

private struct TaskRow: View {
    let task: TodoTask
    let allowsDelete: Bool
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
            if allowsDelete {
                Button(role: .destructive, action: onRequestDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct SummaryTaskRow: View {
    let task: TodoTask

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.62))
                    .frame(width: 42, height: 42)

                Image(systemName: "checkmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.green.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.body.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.84))

                Text("Completed \(task.completedAt?.formatted(date: .omitted, time: .shortened) ?? "")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.55))
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.orange.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
