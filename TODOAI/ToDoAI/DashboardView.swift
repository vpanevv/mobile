import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore

    @State private var activeSheet: ActiveSheet?
    @State private var showingCompletedTasks = false
    @State private var pendingDeleteTask: TodoTask?
    @State private var vanishingTaskIDs: Set<UUID> = []

    let profile: UserProfile

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                heroCard
                actionsRow
                todayTaskSection

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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .taskComposer:
                TaskComposerSheet(onCreate: createTask)
            case .aiAssist:
                AIAssistSheet(userName: profile.name, onAdd: addSuggestedTasks)
            }
        }
        .fullScreenCover(isPresented: $showingCompletedTasks) {
            CompletedTasksView(tasks: allCompletedTasks) {
                showingCompletedTasks = false
            }
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
        HStack {
            actionButton(title: "AI Assist", systemName: "sparkles", isPrimaryAI: true) {
                activeSheet = .aiAssist
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
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
                    Button {
                        showingCompletedTasks = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checklist.checked")
                                .font(.headline.weight(.bold))

                            Text("View completed tasks")
                                .font(.headline.weight(.bold))

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3.weight(.bold))
                        }
                        .foregroundStyle(Color.black.opacity(0.82))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
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

    private var todayTaskSection: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Today")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.88))

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            activeSheet = .taskComposer
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.black))

                                Text("Create task")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(Color.black.opacity(0.78))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.52), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Text(todayOpenTasks.isEmpty ? "Clear board" : "\(todayOpenTasks.count) active")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.black.opacity(0.56))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.36), in: Capsule())
                    }
                }

                if todayOpenTasks.isEmpty {
                    Text("No active tasks yet. Add one to shape your day.")
                        .foregroundStyle(Color.black.opacity(0.62))
                } else {
                    ForEach(todayOpenTasks) { task in
                        TaskRow(
                            task: task,
                            allowsDelete: false,
                            isVanishing: vanishingTaskIDs.contains(task.id),
                            usesDarkText: true,
                            onToggle: {
                                toggleCompletion(for: task)
                            },
                            onRequestDelete: {}
                        )
                    }
                }
            }
            .padding(22)
            .background(todayCardBackground(time: time))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.34), lineWidth: 1.2)
            }
            .shadow(color: Color.orange.opacity(0.16), radius: 22, y: 12)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.top, 2)
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
                            isVanishing: vanishingTaskIDs.contains(task.id),
                            usesDarkText: false,
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

    private var allCompletedTasks: [TodoTask] {
        store.tasks
            .filter(\.isCompleted)
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
        guard !vanishingTaskIDs.contains(task.id) else { return }

        if !task.isCompleted {
            withAnimation(.easeInOut(duration: 0.34)) {
                vanishingTaskIDs.insert(task.id)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                store.toggleCompletion(for: task.id)

                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    vanishingTaskIDs.remove(task.id)
                }
            }
            return
        }

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

    private func todayCardBackground(time: TimeInterval) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.86, blue: 0.62),
                            Color(red: 1.0, green: 0.76, blue: 0.44),
                            Color(red: 1.0, green: 0.94, blue: 0.82),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.34))
                .frame(width: 200, height: 200)
                .blur(radius: 16)
                .offset(x: -120 + cos(time * 0.38) * 10, y: -110 + sin(time * 0.22) * 12)

            Circle()
                .fill(Color.orange.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 22)
                .offset(x: 130 + sin(time * 0.26) * 12, y: 120 + cos(time * 0.20) * 10)
        }
    }
}

private enum ActiveSheet: Identifiable {
    case taskComposer
    case aiAssist

    var id: Int {
        switch self {
        case .taskComposer:
            0
        case .aiAssist:
            1
        }
    }
}

private struct TaskRow: View {
    let task: TodoTask
    let allowsDelete: Bool
    let isVanishing: Bool
    let usesDarkText: Bool
    let onToggle: () -> Void
    let onRequestDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(task.isCompleted ? .green : primaryColor.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(buttonBackgroundColor, in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(primaryColor)
                    .strikethrough(task.isCompleted, color: primaryColor.opacity(0.8))

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
        .background(cardBackgroundColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            if isVanishing {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.cyan.opacity(0.14),
                                .clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .opacity(isVanishing ? 0 : 1)
        .scaleEffect(isVanishing ? 0.92 : 1, anchor: .leading)
        .blur(radius: isVanishing ? 10 : 0)
        .offset(x: isVanishing ? 34 : 0, y: isVanishing ? -6 : 0)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if allowsDelete {
                Button(role: .destructive, action: onRequestDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .animation(.easeInOut(duration: 0.34), value: isVanishing)
    }

    private var primaryColor: Color {
        usesDarkText ? Color.black.opacity(0.82) : .white
    }

    private var cardBackgroundColor: Color {
        usesDarkText ? Color.white.opacity(0.34) : Color.white.opacity(0.08)
    }

    private var buttonBackgroundColor: Color {
        usesDarkText ? Color.white.opacity(task.isCompleted ? 0.52 : 0.26) : Color.white.opacity(task.isCompleted ? 0.18 : 0.08)
    }
}
