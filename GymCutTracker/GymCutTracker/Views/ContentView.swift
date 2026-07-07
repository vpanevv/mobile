import SwiftUI
import PhotosUI
import Combine
import MusicKit
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: FitnessStore

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent") }

            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "figure.strengthtraining.traditional") }

            ActivityCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            ExerciseProgressListView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.badge.checkmark") }

            BodyView()
                .tabItem { Label("Body", systemImage: "person.crop.rectangle.stack") }

            MusicView()
                .tabItem { Label("Music", systemImage: "music.note.list") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.cutAccent)
        .background(Color.cutBlack)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: FitnessStore

    var body: some View {
        PremiumScreen(title: "Gym Cut Tracker", subtitle: "Keep strength while the scale moves down") {
            VStack(spacing: 16) {
                todayCard
                weeklyCompletion
                metricsGrid
                activityProgressCard
                insightCard
            }
        }
    }

    @ViewBuilder
    private var todayCard: some View {
        if let workout = store.todayWorkout {
            workoutTodayCard(workout)
        } else {
            restDayCard
        }
    }

    private func workoutTodayCard(_ workout: WorkoutDay) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today")
                            .metricLabel()
                        Text("\(workout.id.rawValue) - \(workout.title)")
                            .font(.title2.weight(.bold))
                        Text(workout.subtitle)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "bolt.heart.fill")
                        .font(.title2)
                        .foregroundStyle(Color.cutAccent)
                        .frame(width: 44, height: 44)
                        .background(Color.cutAccent.opacity(0.14), in: Circle())
                }

                HStack {
                    Text("\(workout.exercises.count) exercises")
                    Text("\(workout.exercises.reduce(0) { $0 + $1.sets }) sets")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondaryText)

                NavigationLink {
                    WorkoutSessionView(day: workout.id)
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .primaryButtonStyle()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var restDayCard: some View {
        let nextWorkout = store.workout(for: store.nextTrainingDay)

        return PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today")
                            .metricLabel()
                        Text("Rest day")
                            .font(.title2.weight(.bold))
                        Text("Recover, walk, hydrate, and come back strong.")
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundStyle(Color.cutAccent)
                        .frame(width: 44, height: 44)
                        .background(Color.cutAccent.opacity(0.14), in: Circle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.cutAccent)
                        Text("Next: \(nextWorkout.id.rawValue) - Full body workout")
                            .font(.subheadline.weight(.bold))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(Color.cutAccent)
                        Text("Keep steps light and let strength recover.")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(Color.secondaryText)

                Text("No workout scheduled today")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.cutAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.cutAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var weeklyCompletion: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Weekly completion")
                        .sectionTitle()
                    Spacer()
                    Text("\(store.weeklyCompletedDays.count)/3")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.cutAccent)
                }

                HStack(spacing: 10) {
                    ForEach([TrainingDay.monday, TrainingDay.wednesday, TrainingDay.friday], id: \.self) { (day: TrainingDay) in
                        VStack(spacing: 8) {
                            Text(day.shortTitle)
                                .font(.caption.weight(.bold))
                            Image(systemName: store.weeklyCompletedDays.contains(day) ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(store.weeklyCompletedDays.contains(day) ? Color.cutAccent : Color.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Workouts", value: "\(store.totalWorkoutsCompleted)", detail: "completed")
            MetricTile(title: "Body weight", value: store.currentBodyWeight > 0 ? "\(store.currentBodyWeight.clean) kg" : "--", detail: "current")
            MetricTile(title: "Goal weight", value: "\(store.goalBodyWeight.clean) kg", detail: "cut target")
            MetricTile(title: "Strength", value: store.strengthSummary, detail: "summary")
        }
    }

    private var activityProgressCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Training process")
                        .sectionTitle()
                    Spacer()
                    NavigationLink {
                        ActivityCalendarView()
                    } label: {
                        Image(systemName: "calendar")
                            .iconButtonStyle()
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    ActivityPercentBadge(title: "Week", summary: store.currentWeekActivity)
                    ActivityPercentBadge(title: "Month", summary: store.currentMonthActivity)
                }
            }
        }
    }

    private var insightCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Last workout")
                    .sectionTitle()

                if let last = store.lastWorkout {
                    Text("\(last.day.rawValue) - \(last.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.headline.weight(.bold))
                    Text("\(last.formattedDuration) • \(last.exerciseLogs.count) exercises • \(last.exerciseLogs.flatMap(\.setLogs).filter(\.completed).count) sets • \(sessionVolume(last).clean) kg")
                        .foregroundStyle(Color.secondaryText)
                    if last.personalRecords.isEmpty == false {
                        Text("PRs: \(last.personalRecords.joined(separator: ", "))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cutAccent)
                    }
                } else {
                    Text("No sessions saved yet. Start your first workout and this becomes your command center.")
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
    }

    private func sessionVolume(_ session: WorkoutSession) -> Double {
        session.exerciseLogs.flatMap(\.setLogs).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}

struct ActivityCalendarView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var selectedScope: ActivityScope = .month
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        PremiumScreen(title: "Calendar", subtitle: "Weekly and monthly training completion") {
            VStack(spacing: 16) {
                Picker("Scope", selection: $selectedScope) {
                    ForEach(ActivityScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)

                if selectedScope == .week {
                    weekView
                } else {
                    monthView
                }
            }
        }
    }

    private var weekView: some View {
        let summary = store.currentWeekActivity
        return VStack(spacing: 16) {
            ActivityHeroCard(title: "This week", subtitle: "3 planned sessions", summary: summary)

            PremiumCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Training days")
                        .sectionTitle()

                    ForEach(store.weekRows(containing: .now)) { item in
                        if let session = store.completedSession(on: item.date) {
                            NavigationLink {
                                WorkoutSummaryView(sessionID: session.id)
                            } label: {
                                calendarWeekRow(item, session: session)
                            }
                            .buttonStyle(.plain)
                        } else {
                            calendarWeekRow(item, session: nil)
                        }
                    }
                }
            }
        }
    }

    private func calendarWeekRow(_ item: TrainingCalendarDay, session: WorkoutSession?) -> some View {
        HStack(spacing: 12) {
            CalendarStatusIcon(completed: item.completed, scheduled: item.trainingDay != nil)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.trainingDay?.rawValue ?? "Training")
                    .font(.headline.weight(.bold))
                Text(item.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondaryText)
                if let weight = session?.bodyWeightKg {
                    Text("Body weight: \(weight.clean) kg")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.cutAccent)
                }
            }
            Spacer()
            Text(item.completed ? "Done" : "Planned")
                .font(.caption.weight(.bold))
                .foregroundStyle(item.completed ? Color.cutAccent : Color.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.tileFill, in: Capsule())
        }
    }

    private var monthView: some View {
        let summary = store.activitySummary(for: .month, containing: displayedMonth)
        return VStack(spacing: 16) {
            ActivityHeroCard(
                title: displayedMonth.formatted(.dateTime.month(.wide).year()),
                subtitle: "\(summary.scheduledCount) planned sessions",
                summary: summary
            )

            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button { shiftMonth(-1) } label: {
                            Image(systemName: "chevron.left")
                                .iconButtonStyle()
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.headline.weight(.bold))

                        Spacer()

                        Button { shiftMonth(1) } label: {
                            Image(systemName: "chevron.right")
                                .iconButtonStyle()
                        }
                        .buttonStyle(.plain)
                    }

                    weekdayHeader

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(store.calendarDays(forMonthContaining: displayedMonth)) { item in
                            if let session = store.completedSession(on: item.date) {
                                NavigationLink {
                                    WorkoutSummaryView(sessionID: session.id)
                                } label: {
                                    MonthDayCell(item: item, session: session)
                                }
                                .buttonStyle(.plain)
                            } else {
                                MonthDayCell(item: item)
                            }
                        }
                    }
                }
            }

            PremiumCard {
                HStack(spacing: 12) {
                    LegendItem(color: Color.cutAccent, title: "Completed")
                    LegendItem(color: Color.neonBlue.opacity(0.85), title: "Planned")
                    LegendItem(color: Color.white.opacity(0.10), title: "Rest")
                }
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day.uppercased())
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func shiftMonth(_ amount: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: amount, to: displayedMonth) ?? displayedMonth
    }
}

struct WorkoutsView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var selectedDay: TrainingDay = .monday
    @State private var editingExercise: Exercise?
    @State private var isAddingExercise = false

    var body: some View {
        PremiumScreen(title: "Workouts", subtitle: "Edit the A/B/C program from your screenshots") {
            VStack(spacing: 16) {
                Picker("Training day", selection: $selectedDay) {
                    ForEach([TrainingDay.monday, TrainingDay.wednesday, TrainingDay.friday], id: \.self) { (day: TrainingDay) in
                        Text(day.rawValue).tag(day)
                    }
                }
                .pickerStyle(.segmented)

                workoutHeader
                exerciseList
            }
        }
        .sheet(item: $editingExercise) { exercise in
            ExerciseEditorView(day: selectedDay, exercise: exercise)
        }
        .sheet(isPresented: $isAddingExercise) {
            ExerciseEditorView(day: selectedDay, exercise: nil)
        }
    }

    private var workoutHeader: some View {
        let workout = store.workout(for: selectedDay)
        return PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.title)
                            .font(.title2.weight(.bold))
                        Text(workout.subtitle)
                            .foregroundStyle(Color.secondaryText)
                    }
                    Spacer()
                    NavigationLink {
                        WorkoutSessionView(day: selectedDay)
                    } label: {
                        Image(systemName: "play.fill")
                            .iconButtonStyle()
                    }
                    .buttonStyle(.plain)
                }
                Text("Finisher: \(workout.finisher)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cutAccent)
            }
        }
    }

    private var exerciseList: some View {
        PremiumCard {
            VStack(spacing: 10) {
                HStack {
                    Text("Exercises")
                        .sectionTitle()
                    Spacer()
                    Button { isAddingExercise = true } label: {
                        Image(systemName: "plus")
                            .iconButtonStyle()
                    }
                    .buttonStyle(.plain)
                }

                List {
                    ForEach(store.workout(for: selectedDay).exercises) { exercise in
                        Button { editingExercise = exercise } label: {
                            ExerciseProgramRow(exercise: exercise)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { store.deleteExercises(day: selectedDay, offsets: $0) }
                    .onMove { store.moveExercises(day: selectedDay, from: $0, to: $1) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 420)
            }
        }
    }
}

struct WorkoutSessionView: View {
    @EnvironmentObject private var store: FitnessStore
    @EnvironmentObject private var music: AppleMusicManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gym-cut.live-activities-enabled") private var liveActivitiesEnabled = true
    @AppStorage("gym-cut.auto-start-workout-music") private var autoStartWorkoutMusic = false
    let day: TrainingDay

    @StateObject private var sessionTimer = WorkoutSessionTimerManager()
    @State private var logs: [ExerciseLog] = []
    @State private var notes = ""
    @State private var showingSummary = false
    @State private var savedSession: WorkoutSession?
    @State private var restEndDate: Date?
    @State private var pausedRestRemaining: TimeInterval?
    @State private var previousCompletedSetCount = 0
    @State private var didFinishWorkout = false
    @State private var showingMusicPrompt = false
    @State private var showingMusicPlayer = false
    @State private var showingKeepMusicPrompt = false
    @State private var pendingFinishedSession: WorkoutSession?
    @State private var showingFinishConfirmation = false

    private let liveActivityTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        PremiumScreen(title: store.workout(for: day).title, subtitle: "Log each set, then finish") {
            VStack(spacing: 16) {
                SessionTimerCard(
                    timer: sessionTimer,
                    onPauseResume: toggleSessionTimerPause,
                    onFinish: requestFinishWorkout
                )

                WorkoutMusicPlayerCard(workoutDay: day)
                    .environmentObject(music)
                    .onTapGesture {
                        showingMusicPlayer = true
                    }

                ForEach($logs) { $log in
                    ExerciseLogCard(log: $log)
                }

                PremiumCard {
                    TextField("Workout notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                }

                Button { requestFinishWorkout() } label: {
                    Label("Finish Workout", systemImage: "checkmark.circle.fill")
                        .primaryButtonStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear(perform: buildLogsIfNeeded)
        .onAppear {
            sessionTimer.startIfNeeded()
        }
        .task {
            await prepareWorkoutMusicIfNeeded()
        }
        .onChange(of: logs) { _, _ in
            handleLoggedSetsChanged()
        }
        .onReceive(liveActivityTimer) { _ in
            sessionTimer.updateDisplayedDuration()
            updateLiveActivity(status: liveStatusText)
        }
        .onDisappear {
            if didFinishWorkout == false {
                GymWorkoutLiveActivityManager.shared.cancel()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSummary) {
            if let savedSession {
                WorkoutSummaryView(sessionID: savedSession.id, promptForWeight: true)
            }
        }
        .sheet(isPresented: $showingMusicPlayer) {
            ExpandedMusicPlayerSheet()
                .environmentObject(music)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Start workout music?", isPresented: $showingMusicPrompt, titleVisibility: .visible) {
            Button("Play") {
                Task { await playWorkoutMusic() }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            if let selection = store.musicSelection(for: day) {
                Text(selection.title)
            }
        }
        .confirmationDialog("Keep music playing?", isPresented: $showingKeepMusicPrompt, titleVisibility: .visible) {
            Button("Keep Playing") {
                savePendingFinishedSession(stopMusic: false)
            }
            Button("Stop Music", role: .destructive) {
                savePendingFinishedSession(stopMusic: true)
            }
        }
        .confirmationDialog("Finish workout?", isPresented: $showingFinishConfirmation, titleVisibility: .visible) {
            Button("Finish Workout") {
                finishWorkout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your workout session will be saved with the current duration.")
        }
        .dismissKeyboardOnTap()
    }

    private func buildLogsIfNeeded() {
        guard logs.isEmpty else { return }
        logs = store.workout(for: day).exercises.map { exercise in
            ExerciseLog(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                muscleGroup: exercise.muscleGroup,
                targetReps: exercise.targetReps,
                setLogs: (1...exercise.sets).map { SetLog(setNumber: $0) }
            )
        }
        previousCompletedSetCount = completedSetCount
        startLiveActivityIfNeeded()
    }

    private func requestFinishWorkout() {
        showingFinishConfirmation = true
    }

    private func toggleSessionTimerPause() {
        if sessionTimer.isPaused {
            sessionTimer.resume()
            if let pausedRestRemaining, pausedRestRemaining > 0 {
                restEndDate = Date().addingTimeInterval(pausedRestRemaining)
            }
            self.pausedRestRemaining = nil
        } else {
            if let restEndDate, restEndDate > .now {
                pausedRestRemaining = restEndDate.timeIntervalSince(.now)
            }
            sessionTimer.pause()
        }

        updateLiveActivity(status: liveStatusText)
    }

    private func finishWorkout() {
        let timing = sessionTimer.stop()
        let session = WorkoutSession(
            date: timing.finishedAt,
            day: day,
            exerciseLogs: logs,
            durationMinutes: max(Int(ceil(Double(timing.durationSeconds) / 60)), 1),
            startedAt: timing.startedAt,
            finishedAt: timing.finishedAt,
            durationSeconds: timing.durationSeconds,
            totalPausedSeconds: timing.totalPausedSeconds,
            isPaused: false,
            pausedAt: nil,
            completedAt: timing.finishedAt,
            notes: notes
        )
        if music.isPlaying {
            pendingFinishedSession = session
            showingKeepMusicPrompt = true
            return
        }

        completeWorkout(with: session)
    }

    private func completeWorkout(with session: WorkoutSession) {
        store.saveSession(session)
        savedSession = store.lastWorkout
        didFinishWorkout = true
        endLiveActivity(with: store.lastWorkout ?? session)
        showingSummary = true
    }

    private func savePendingFinishedSession(stopMusic: Bool) {
        guard let pendingFinishedSession else { return }
        if stopMusic {
            music.stop()
        }
        self.pendingFinishedSession = nil
        completeWorkout(with: pendingFinishedSession)
    }

    private func prepareWorkoutMusicIfNeeded() async {
        await music.requestPermissionIfNeeded()
        guard store.musicSelection(for: day) != nil else { return }
        if autoStartWorkoutMusic {
            await playWorkoutMusic()
        } else if music.authorizationStatus == .authorized {
            showingMusicPrompt = true
        }
    }

    private func playWorkoutMusic() async {
        guard let selection = store.musicSelection(for: day) else { return }
        await music.play(selection: selection)
    }

    private func startLiveActivityIfNeeded() {
        guard liveActivitiesEnabled else { return }
        let workout = store.workout(for: day)
        let attributes = GymWorkoutActivityAttributes(
            workoutSessionId: UUID().uuidString,
            workoutDayName: day.rawValue,
            workoutName: workout.title
        )
        GymWorkoutLiveActivityManager.shared.start(attributes: attributes, state: liveActivityState(status: "Workout started"))
    }

    private func handleLoggedSetsChanged() {
        let completed = completedSetCount

        if completed > previousCompletedSetCount {
            startRestAfterLatestSet()
        }

        previousCompletedSetCount = completed
        updateLiveActivity(status: liveStatusText)
    }

    private func startRestAfterLatestSet() {
        guard let latest = latestCompletedSetContext else { return }
        let workout = store.workout(for: day)
        guard latest.exerciseIndex < workout.exercises.count else { return }
        let restSeconds = workout.exercises[latest.exerciseIndex].restSeconds
        restEndDate = Date().addingTimeInterval(TimeInterval(restSeconds))
    }

    private func updateLiveActivity(status: String) {
        guard liveActivitiesEnabled else { return }
        GymWorkoutLiveActivityManager.shared.update(liveActivityState(status: status))
    }

    private func endLiveActivity(with session: WorkoutSession) {
        guard liveActivitiesEnabled else { return }
        let finalState = liveActivityState(
            status: "Workout Complete",
            isComplete: true,
            personalRecordCount: session.personalRecords.count
        )
        GymWorkoutLiveActivityManager.shared.end(finalState: finalState)
    }

    private var liveStatusText: String {
        if sessionTimer.isPaused {
            return "Paused"
        }
        if isResting {
            return "Resting"
        }
        if restEndDate != nil {
            return "Ready for next set"
        }
        return "Keep the pace"
    }

    private var isResting: Bool {
        if sessionTimer.isPaused { return false }
        guard let restEndDate else { return false }
        return restEndDate > .now
    }

    private var completedSetCount: Int {
        logs.flatMap(\.setLogs).filter(\.completed).count
    }

    private var totalVolumeSoFar: Double {
        logs.flatMap(\.setLogs).filter(\.completed).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var latestCompletedSetContext: (exerciseIndex: Int, set: SetLog)? {
        for exerciseIndex in logs.indices.reversed() {
            if let set = logs[exerciseIndex].setLogs.last(where: { $0.completed }) {
                return (exerciseIndex, set)
            }
        }
        return nil
    }

    private var currentExerciseContext: (exerciseIndex: Int, exerciseLog: ExerciseLog, setNumber: Int) {
        for exerciseIndex in logs.indices {
            if let nextSet = logs[exerciseIndex].setLogs.first(where: { $0.completed == false }) {
                return (exerciseIndex, logs[exerciseIndex], nextSet.setNumber)
            }
        }

        let fallbackIndex = max(logs.count - 1, 0)
        let fallbackLog = logs.isEmpty
            ? ExerciseLog(exerciseID: UUID(), exerciseName: "Workout", muscleGroup: "", targetReps: "", setLogs: [SetLog(setNumber: 1)])
            : logs[fallbackIndex]
        return (fallbackIndex, fallbackLog, fallbackLog.setLogs.count)
    }

    private func liveActivityState(
        status: String,
        isComplete: Bool = false,
        personalRecordCount: Int = 0
    ) -> GymWorkoutActivityAttributes.ContentState {
        let current = currentExerciseContext
        let latestSet = latestCompletedSetContext?.set

        return GymWorkoutActivityAttributes.ContentState(
            currentExerciseName: current.exerciseLog.exerciseName,
            currentExerciseIndex: current.exerciseIndex + 1,
            totalExercises: max(logs.count, 1),
            currentSetNumber: current.setNumber,
            totalSetsForExercise: current.exerciseLog.setLogs.count,
            targetWeight: latestSet?.weight ?? 0,
            targetReps: current.exerciseLog.targetReps,
            lastSetWeight: latestSet?.weight ?? 0,
            lastSetReps: latestSet?.reps ?? 0,
            completedSets: completedSetCount,
            totalVolume: totalVolumeSoFar,
            workoutStartTime: sessionTimer.startedAt ?? .now,
            workoutDuration: TimeInterval(sessionTimer.activeDurationSeconds),
            isPaused: sessionTimer.isPaused,
            isResting: isResting,
            restEndTime: isResting ? restEndDate : nil,
            statusText: status,
            isComplete: isComplete,
            personalRecordCount: personalRecordCount
        )
    }
}

struct ExerciseProgressListView: View {
    @EnvironmentObject private var store: FitnessStore

    var body: some View {
        PremiumScreen(title: "Progress", subtitle: "Exercise history and trend signals") {
            VStack(spacing: 14) {
                ForEach(store.allExerciseProgress) { progress in
                    NavigationLink {
                        ExerciseProgressDetailView(progress: progress)
                    } label: {
                        ProgressRow(progress: progress)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ExerciseProgressDetailView: View {
    let progress: ExerciseProgress

    var body: some View {
        PremiumScreen(title: progress.exercise.name, subtitle: progress.trend.rawValue) {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricTile(title: "Last", value: progress.lastSetSummary, detail: "performed")
                    MetricTile(title: "Best weight", value: "\(progress.bestWeight.clean) kg", detail: "top set")
                    MetricTile(title: "Best reps", value: "\(progress.bestReps)", detail: "single set")
                    MetricTile(title: "Est. 1RM", value: "\(progress.estimatedOneRepMax.clean) kg", detail: "Epley")
                }

                PremiumCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Volume over time")
                            .sectionTitle()
                        MiniBarChart(points: progress.volumeBySession.map(\.1))
                    }
                }

                PremiumCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .sectionTitle()
                        if progress.logs.isEmpty {
                            Text("No logs yet for this exercise.")
                                .foregroundStyle(Color.secondaryText)
                        } else {
                            ForEach(Array(zip(progress.sessions, progress.logs)), id: \.0.id) { session, log in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.headline.weight(.bold))
                                    Text(log.setLogs.map { "\($0.weight.clean) kg x \($0.reps)" }.joined(separator: "  |  "))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondaryText)
                                }
                                Divider().overlay(Color.white.opacity(0.08))
                            }
                        }
                    }
                }
            }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var searchText = ""
    @State private var sortOption: PersonalBestSortOption = .latestPR
    @State private var checkInType: WeightCheckInType?

    private var filteredPersonalBests: [ExercisePersonalBest] {
        let searched = store.exercisePersonalBests.filter { best in
            searchText.isEmpty ||
            best.exerciseName.localizedCaseInsensitiveContains(searchText) ||
            (best.muscleGroup ?? "").localizedCaseInsensitiveContains(searchText)
        }

        switch sortOption {
        case .exerciseName:
            return searched.sorted { $0.exerciseName.localizedCaseInsensitiveCompare($1.exerciseName) == .orderedAscending }
        case .latestPR:
            return searched.sorted { $0.achievedAt > $1.achievedAt }
        case .highestWeight:
            return searched.sorted { $0.bestWeight > $1.bestWeight }
        case .muscleGroup:
            return searched.sorted {
                ($0.muscleGroup ?? "").localizedCaseInsensitiveCompare($1.muscleGroup ?? "") == .orderedAscending
            }
        }
    }

    var body: some View {
        PremiumScreen(title: "History", subtitle: "Track your consistency, strength, and cut progress") {
            VStack(spacing: 16) {
                currentWeekCard
                currentMonthCard
                personalBestsCard
                weightCheckInsCard
                workoutHistoryCard
            }
        }
        .sheet(item: $checkInType) { type in
            WeightCheckInSheet(type: type)
                .environmentObject(store)
                .presentationDetents([.medium])
        }
    }

    private var currentWeekCard: some View {
        let summary = store.historyWeekSummary()

        return PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Week")
                            .sectionTitle()
                        Text("\(summary.startDate.formatted(.dateTime.month(.abbreviated).day())) - \(summary.endDate.formatted(.dateTime.month(.abbreviated).day()))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()

                    Text("\(summary.completedCount)/\(summary.targetCount)")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.cutAccent)
                }

                Text("\(summary.completedCount) / \(summary.targetCount) workouts completed")
                    .font(.headline.weight(.bold))

                HStack(spacing: 10) {
                    ForEach(summary.rows) { row in
                        VStack(spacing: 8) {
                            Text(row.trainingDay?.shortTitle ?? "")
                                .font(.caption.weight(.black))
                            Image(systemName: row.completed ? "checkmark.circle.fill" : "circle")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(row.completed ? Color.cutAccent : Color.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                Text(summary.status)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.cutAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.cutAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var currentMonthCard: some View {
        let summary = store.historyMonthSummary()

        return PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Month")
                            .sectionTitle()
                        Text(summary.monthDate.formatted(.dateTime.month(.wide).year()))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()

                    Text("\(summary.consistency)%")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.cutAccent)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricTile(title: "Workouts", value: "\(summary.completedCount)/\(summary.expectedCount)", detail: "completed")
                    MetricTile(title: "Perfect weeks", value: "\(summary.perfectWeeks)", detail: "\(summary.completedWeeks) active weeks")
                    MetricTile(title: "Missed", value: "\(summary.missedCount)", detail: "scheduled sessions")
                    MetricTile(title: "Streak", value: "\(summary.currentTrainingStreak)", detail: "sessions")
                }

                HStack(spacing: 10) {
                    HistoryMiniStat(title: "Best week", value: "\(summary.bestTrainingWeekCount) workouts")
                    HistoryMiniStat(title: "Best streak", value: "\(summary.bestMonthlyStreak) sessions")
                }
            }
        }
    }

    private var personalBestsCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Personal Bests")
                    .sectionTitle()

                TextField("Search exercise", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Picker("Sort", selection: $sortOption) {
                    ForEach(PersonalBestSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.cutAccent)

                if filteredPersonalBests.isEmpty {
                    Text("No personal bests yet. Complete workouts with logged sets to build this list.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                } else {
                    ForEach(filteredPersonalBests) { best in
                        PersonalBestCard(best: best)
                    }
                }
            }
        }
    }

    private var weightCheckInsCard: some View {
        let checkIns = store.sortedWeightCheckIns
        let latest = checkIns.first
        let previous = checkIns.dropFirst().first
        let weekly = checkIns.first { $0.type == .weekly }
        let monthly = checkIns.first { $0.type == .monthly }
        let startWeight = checkIns.last?.weightKg ?? store.sortedBodyEntries.last?.weightKg ?? store.currentBodyWeight
        let currentWeight = latest?.weightKg ?? store.currentBodyWeight
        let lost = currentWeight > 0 && startWeight > 0 ? currentWeight - startWeight : 0
        let change = latest.flatMap { latest in previous.map { latest.weightKg - $0.weightKg } }

        return PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Weight Check-ins")
                    .sectionTitle()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricTile(title: "Current", value: currentWeight > 0 ? "\(currentWeight.clean) kg" : "--", detail: "latest")
                    MetricTile(title: "Goal", value: "\(store.goalBodyWeight.clean) kg", detail: "cut target")
                    MetricTile(title: "Lost", value: "\(lost.clean) kg", detail: "from start")
                    MetricTile(title: "This check-in", value: change.map { "\($0.clean) kg" } ?? "--", detail: "change")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(weightTrendText(change: change))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(weightTrendColor(change: change))
                    Text("Weekly: \(weekly.map { "\($0.weightKg.clean) kg" } ?? "--")  •  Monthly: \(monthly.map { "\($0.weightKg.clean) kg" } ?? "--")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                }

                HStack(spacing: 10) {
                    Button { checkInType = .weekly } label: {
                        Label("Add Weekly", systemImage: "calendar.badge.plus")
                            .secondaryButtonStyle()
                    }
                    .buttonStyle(.plain)

                    Button { checkInType = .monthly } label: {
                        Label("Add Monthly", systemImage: "calendar")
                            .secondaryButtonStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var workoutHistoryCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Workout History")
                    .sectionTitle()

                if store.completedWorkoutSessions.isEmpty {
                    Text("No completed workouts yet. Finished sessions will appear here with duration, volume, sets, and share-card quote.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                } else {
                    ForEach(store.completedWorkoutSessions) { session in
                        NavigationLink {
                            WorkoutSummaryView(sessionID: session.id)
                        } label: {
                            WorkoutHistoryRow(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func weightTrendText(change: Double?) -> String {
        guard let change else { return "No check-ins yet" }
        if change < -0.05 { return "Down \(abs(change).clean) kg since last check-in" }
        if change > 0.05 { return "Up \(change.clean) kg since last check-in" }
        return "Weight stayed steady since last check-in"
    }

    private func weightTrendColor(change: Double?) -> Color {
        guard let change else { return Color.secondaryText }
        if change < -0.05 { return Color.cutAccent }
        if change > 0.05 { return Color.orange }
        return Color.secondaryText
    }
}

private enum PersonalBestSortOption: String, CaseIterable, Identifiable {
    case latestPR = "Latest PR"
    case exerciseName = "Exercise"
    case highestWeight = "Weight"
    case muscleGroup = "Muscle"

    var id: String { rawValue }
}

private struct WeightCheckInSheet: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    let type: WeightCheckInType

    @State private var date = Date()
    @State private var weight = 0.0
    @State private var waistText = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cutBlack.ignoresSafeArea()

                VStack(spacing: 16) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .foregroundStyle(.white)
                        .tint(Color.cutAccent)

                    NumberField(title: "kg", value: $weight)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Waist cm optional", text: $waistText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    TextField("Note optional", text: $note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button { save() } label: {
                        Label("Save \(type.rawValue) Check-in", systemImage: "checkmark.circle.fill")
                            .primaryButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .disabled(weight <= 0)
                }
                .padding(20)
            }
            .navigationTitle("\(type.rawValue) Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            weight = store.currentBodyWeight > 0 ? store.currentBodyWeight : 0
        }
        .dismissKeyboardOnTap()
    }

    private func save() {
        let waist = Double(waistText.replacingOccurrences(of: ",", with: "."))
        store.addWeightCheckIn(
            WeightCheckIn(
                date: date,
                weightKg: weight,
                waistCm: waist,
                note: note.isEmpty ? nil : note,
                type: type
            )
        )
        dismiss()
    }
}

private struct PostWorkoutWeightSheet: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    let sessionID: UUID
    let sessionDate: Date

    @State private var weight = 0.0
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cutBlack.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Post-workout weight")
                            .font(.title2.weight(.black))
                        Text("Save today’s body weight with this gym session.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.secondaryText)
                    }

                    NumberField(title: "kg", value: $weight)

                    TextField("Optional note", text: $note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button { save() } label: {
                        Label("Save Weight", systemImage: "scalemass.fill")
                            .primaryButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .disabled(weight <= 0)

                    Button("Skip for this session") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let existing = store.session(id: sessionID)?.bodyWeightKg {
                weight = existing
            } else if store.currentBodyWeight > 0 {
                weight = store.currentBodyWeight
            }
        }
        .dismissKeyboardOnTap()
    }

    private func save() {
        store.updateSessionBodyWeight(weight, for: sessionID)
        store.addBodyEntry(
            BodyProgress(
                date: sessionDate,
                weightKg: weight,
                goalWeightKg: store.goalBodyWeight,
                notes: note.isEmpty ? "Post-workout check-in" : note
            )
        )
        dismiss()
    }
}

private struct PersonalBestCard: View {
    let best: ExercisePersonalBest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(best.exerciseName)
                        .font(.headline.weight(.black))
                    Text(best.muscleGroup ?? "Exercise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.secondaryText)
                }
                Spacer()
                Text(best.achievedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.cutAccent)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                HistoryMiniStat(title: "Best weight", value: "\(best.bestWeight.clean) kg x \(best.bestReps)")
                HistoryMiniStat(title: "Set volume", value: "\(best.bestSetVolume.clean) kg")
                HistoryMiniStat(title: "Session volume", value: "\(best.bestSessionVolume.clean) kg")
                HistoryMiniStat(title: "Last PR", value: best.achievedAt.formatted(.dateTime.month(.abbreviated).day()))
            }
        }
        .padding(12)
        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WorkoutHistoryRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            sessionThumbnail

            VStack(alignment: .leading, spacing: 5) {
                Text("\(session.day.rawValue) - \(session.day.programTitle)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.cutAccent)
                Text("\(session.formattedDuration) • \(session.exerciseLogs.count) exercises • \(session.completedSets) sets • \(session.totalVolume.clean) kg")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
                if let bodyWeight = session.bodyWeightKg {
                    Text("Body weight: \(bodyWeight.clean) kg")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.cutAccent)
                }
                if let quote = session.motivationalQuote {
                    Text("\"\(quote)\"")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(12)
        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var sessionThumbnail: some View {
        Group {
            if let url = session.sessionPhotoURL, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.cutAccent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.cutAccent.opacity(0.12))
            }
        }
        .frame(width: 54, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HistoryMiniStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.secondaryText)
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct BodyView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var weight = 86.0
    @State private var goal = 80.0
    @State private var notes = ""

    var body: some View {
        PremiumScreen(title: "Body", subtitle: "Scale, goal, weekly check-ins") {
            VStack(spacing: 16) {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New check-in")
                            .sectionTitle()
                        MeasurementStepper(title: "Weight", value: $weight, suffix: "kg", range: 40...180, step: 0.1)
                        MeasurementStepper(title: "Goal", value: $goal, suffix: "kg", range: 40...180, step: 0.1)
                        TextField("Weekly notes", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Button { saveBodyEntry() } label: {
                            Label("Save Check-in", systemImage: "plus.circle.fill")
                                .primaryButtonStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }

                PremiumCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Cutting progress")
                            .sectionTitle()
                        MiniBarChart(points: store.sortedBodyEntries.reversed().map(\.weightKg))
                        Text("Progress photos are modeled and ready for the next iteration; this MVP focuses on body weight and goal tracking.")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                PremiumCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .sectionTitle()
                        ForEach(store.sortedBodyEntries) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.headline.weight(.bold))
                                    Text(entry.notes.isEmpty ? "No notes" : entry.notes)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondaryText)
                                }
                                Spacer()
                                Text("\(entry.weightKg.clean) kg")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color.cutAccent)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            weight = store.currentBodyWeight > 0 ? store.currentBodyWeight : 86
            goal = store.goalBodyWeight
        }
        .dismissKeyboardOnTap()
    }

    private func saveBodyEntry() {
        store.addBodyEntry(BodyProgress(weightKg: weight, goalWeightKg: goal, notes: notes))
        notes = ""
    }
}

struct MusicView: View {
    @EnvironmentObject private var store: FitnessStore
    @EnvironmentObject private var music: AppleMusicManager
    @AppStorage("gym-cut.auto-start-workout-music") private var autoStartWorkoutMusic = false
    @State private var searchText = ""
    @State private var selectedDay: TrainingDay = .monday
    @State private var showingPlayer = false

    var body: some View {
        PremiumScreen(title: "Music", subtitle: "Apple Music for focused lifting") {
            VStack(spacing: 16) {
                authorizationContent
            }
        }
        .task {
            music.refreshAuthorization()
            await music.checkSubscription()
            await music.fetchLibraryPlaylists()
        }
        .task(id: searchText) {
            try? await Task.sleep(for: .milliseconds(350))
            await music.search(term: searchText)
        }
        .sheet(isPresented: $showingPlayer) {
            ExpandedMusicPlayerSheet()
                .environmentObject(music)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var authorizationContent: some View {
        switch music.authorizationStatus {
        case .notDetermined:
            AppleMusicPermissionCard(
                title: "Connect Apple Music",
                message: "Allow Gym Cut Tracker to search Apple Music and play workout music inside your session.",
                buttonTitle: "Connect Apple Music"
            ) {
                Task {
                    await music.requestPermissionIfNeeded()
                    await music.checkSubscription()
                    await music.fetchLibraryPlaylists()
                }
            }
        case .authorized:
            connectedContent
        case .denied, .restricted:
            AppleMusicPermissionCard(
                title: "Apple Music access is disabled",
                message: "Enable Apple Music from Settings to use workout music.",
                buttonTitle: "Open Settings"
            ) {
                music.openAppSettings()
            }
        @unknown default:
            AppleMusicPermissionCard(
                title: "Apple Music unavailable",
                message: "Music access is not available on this device right now.",
                buttonTitle: "Refresh"
            ) {
                music.refreshAuthorization()
            }
        }
    }

    private var connectedContent: some View {
        VStack(spacing: 16) {
            PremiumCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Music Connected")
                                .font(.headline.weight(.black))
                            Text(music.subscriptionAllowsPlayback ? "Choose music for Monday, Wednesday, and Friday." : "Playback may require an Apple Music subscription.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "music.note")
                            .font(.title2.weight(.black))
                            .foregroundStyle(Color.cutAccent)
                    }

                    Toggle("Auto-start workout music", isOn: $autoStartWorkoutMusic)
                        .font(.subheadline.weight(.bold))
                        .tint(Color.cutAccent)
                }
            }

            workoutAssignments

            PremiumCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search Apple Music")
                        .sectionTitle()

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.secondaryText)
                        TextField("Songs, albums, playlists", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Picker("Assign to", selection: $selectedDay) {
                        ForEach(TrainingDay.allCases) { day in
                            Text(day.shortTitle).tag(day)
                        }
                    }
                    .pickerStyle(.segmented)

                    if music.isSearching {
                        ProgressView()
                            .tint(Color.cutAccent)
                    } else if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 && music.searchResults.isEmpty {
                        EmptyMusicState(text: "No Apple Music results found.")
                    } else {
                        ForEach(music.searchResults) { result in
                            MusicResultRow(result: result, selectedDay: selectedDay)
                        }
                    }
                }
            }

            if music.libraryPlaylists.isEmpty == false {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Library")
                            .sectionTitle()
                        ForEach(music.libraryPlaylists) { result in
                            MusicResultRow(result: result, selectedDay: selectedDay)
                        }
                    }
                }
            }

            WorkoutMusicPlayerCard(workoutDay: selectedDay)
                .onTapGesture {
                    showingPlayer = true
                }

            if let error = music.errorMessage {
                Text(error)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var workoutAssignments: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Workout Defaults")
                    .sectionTitle()

                ForEach(TrainingDay.allCases) { day in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(day.rawValue) • \(day.programTitle)")
                                .font(.subheadline.weight(.black))
                            Text(store.musicSelection(for: day)?.title ?? "No music selected")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()

                        if store.musicSelection(for: day) != nil {
                            Button {
                                store.deleteMusicSelection(for: day)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .foregroundStyle(Color.secondaryText)
                        }
                    }

                    if day != TrainingDay.allCases.last {
                        Divider().overlay(Color.white.opacity(0.08))
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: FitnessStore
    @AppStorage("gym-cut.live-activities-enabled") private var liveActivitiesEnabled = true
    @AppStorage("gym-cut.auto-start-workout-music") private var autoStartWorkoutMusic = false

    var body: some View {
        PremiumScreen(title: "Settings", subtitle: "Program rules and cut targets") {
            VStack(spacing: 16) {
                PremiumCard {
                    Toggle(isOn: $liveActivitiesEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Live Activity during workout")
                                .font(.headline.weight(.bold))
                            Text("Show the active gym session on the Lock Screen and Dynamic Island.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                    .tint(Color.cutAccent)
                }

                PremiumCard {
                    Toggle(isOn: $autoStartWorkoutMusic) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-start workout music")
                                .font(.headline.weight(.bold))
                            Text("Play the saved Apple Music selection when a workout starts.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                    .tint(Color.cutAccent)
                }

                PremiumCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Training rules")
                            .sectionTitle()
                        RuleRow(icon: "timer", text: "Heavy exercises: 90-120 sec rest")
                        RuleRow(icon: "timer.circle", text: "Isolation work: 45-60 sec rest")
                        RuleRow(icon: "flame.fill", text: "Keep 1-2 reps in reserve")
                        RuleRow(icon: "figure.walk", text: "After strength: 15-20 min incline walk")
                        RuleRow(icon: "shoeprints.fill", text: "Daily steps target: 8-12K")
                    }
                }

                PremiumCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Local MVP")
                            .sectionTitle()
                        Text("Data is stored on device with editable workout days, completed sessions, exercise history, and body check-ins. No social features or subscriptions.")
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
        }
    }
}

private struct ExerciseProgramRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.iconName ?? "dumbbell.fill")
                .foregroundStyle(Color.cutAccent)
                .frame(width: 34, height: 34)
                .background(Color.cutAccent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(exercise.sets) x \(exercise.targetReps)  -  \(exercise.muscleGroup)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

private struct ExerciseLogCard: View {
    @EnvironmentObject private var store: FitnessStore
    @Binding var log: ExerciseLog

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.exerciseName)
                            .font(.headline.weight(.bold))
                        Text("\(log.muscleGroup) - target \(log.targetReps)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.secondaryText)
                    }
                    Spacer()
                }

                ForEach($log.setLogs) { $set in
                    SetLogRow(set: $set)
                }

                Text(store.recommendation(for: log))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.cutAccent)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cutAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

private struct SessionTimerCard: View {
    @ObservedObject var timer: WorkoutSessionTimerManager
    let onPauseResume: () -> Void
    let onFinish: () -> Void

    var body: some View {
        PremiumCard {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Session Time")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.cutAccent)
                    Text(timer.formattedTime)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(timer.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(timer.isPaused ? Color.orange : Color.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    Button(action: onPauseResume) {
                        Label(timer.isPaused ? "Resume" : "Pause", systemImage: timer.isPaused ? "play.fill" : "pause.fill")
                            .font(.caption.weight(.black))
                            .frame(width: 104)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onFinish) {
                        Label("Finish", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.black))
                            .frame(width: 104)
                            .padding(.vertical, 10)
                            .background(Color.cutAccent, in: Capsule())
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SetLogRow: View {
    @Binding var set: SetLog

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Set \(set.setNumber)")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Toggle("", isOn: $set.completed)
                    .labelsHidden()
                    .tint(.cutAccent)
            }

            HStack(spacing: 10) {
                NumberField(title: "kg", value: $set.weight)
                IntField(title: "reps", value: $set.reps)
                Stepper("RPE \(set.rpe)", value: $set.rpe, in: 1...10)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: 120)
            }
        }
        .padding(12)
        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ExerciseEditorView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    let day: TrainingDay
    let exercise: Exercise?

    @State private var name = ""
    @State private var muscleGroup = ""
    @State private var sets = 3
    @State private var targetReps = "8-10"
    @State private var restSeconds = 90
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                    TextField("Muscle group", text: $muscleGroup)
                    Stepper("Sets: \(sets)", value: $sets, in: 1...8)
                    TextField("Target reps", text: $targetReps)
                    Stepper("Rest: \(restSeconds) sec", value: $restSeconds, in: 30...180, step: 15)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(exercise == nil ? "Add Exercise" : "Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let exercise else { return }
        name = exercise.name
        muscleGroup = exercise.muscleGroup
        sets = exercise.sets
        targetReps = exercise.targetReps
        restSeconds = exercise.restSeconds
        notes = exercise.notes
    }

    private func save() {
        let updated = Exercise(
            id: exercise?.id ?? UUID(),
            name: name,
            muscleGroup: muscleGroup,
            sets: sets,
            targetReps: targetReps,
            restSeconds: restSeconds,
            notes: notes,
            iconName: exercise?.iconName ?? "dumbbell.fill"
        )
        if exercise == nil {
            store.addExercise(to: day, exercise: updated)
        } else {
            store.updateExercise(day: day, exercise: updated)
        }
        dismiss()
    }
}

private struct WorkoutSummaryView: View {
    @EnvironmentObject private var store: FitnessStore
    let sessionID: UUID
    var promptForWeight = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var shareCardURL: URL?
    @State private var sharingItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var statusMessage = ""
    @State private var showingWeightEntry = false

    private var session: WorkoutSession? {
        store.session(id: sessionID)
    }

    var body: some View {
        Group {
            if let session {
                PremiumScreen(title: "Workout Saved", subtitle: session.day.rawValue) {
                    VStack(spacing: 16) {
                        summaryGrid(session)
                        sessionWeightCard(session)
                        sessionPhotoCard(session)
                        shareCardActions(session)
                        recommendationsCard(session)
                    }
                }
            } else {
                PremiumScreen(title: "Workout Saved", subtitle: "Session not found") {
                    PremiumCard {
                        Text("This workout session is no longer available.")
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task { await loadSelectedPhoto(item) }
        }
        .onAppear {
            if promptForWeight, session?.bodyWeightKg == nil {
                showingWeightEntry = true
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                store.attachSessionPhoto(image, to: sessionID)
                statusMessage = "Session photo attached."
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: sharingItems)
        }
        .sheet(isPresented: $showingWeightEntry) {
            if let session {
                PostWorkoutWeightSheet(sessionID: session.id, sessionDate: session.date)
                    .environmentObject(store)
                    .presentationDetents([.medium])
            }
        }
    }

    private func summaryGrid(_ session: WorkoutSession) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Duration", value: session.formattedDuration, detail: "active time")
            MetricTile(title: "Body weight", value: session.bodyWeightKg.map { "\($0.clean) kg" } ?? "--", detail: "after workout")
            MetricTile(title: "Exercises", value: "\(session.exerciseLogs.count)", detail: "completed")
            MetricTile(title: "Sets", value: "\(session.completedSets)", detail: "completed")
        }
    }

    private func sessionWeightCard(_ session: WorkoutSession) -> some View {
        PremiumCard {
            HStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.cutAccent)
                    .frame(width: 42, height: 42)
                    .background(Color.cutAccent.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Session weight")
                        .font(.headline.weight(.bold))
                    Text(session.bodyWeightKg.map { "\($0.clean) kg saved for this workout" } ?? "No weight saved for this session yet.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Button {
                    showingWeightEntry = true
                } label: {
                    Text(session.bodyWeightKg == nil ? "Add" : "Edit")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.cutAccent, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sessionPhotoCard(_ session: WorkoutSession) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Session photo")
                        .sectionTitle()
                    Spacer()
                    if session.sessionPhotoURL != nil {
                        Button(role: .destructive) {
                            store.removeSessionPhoto(from: session.id)
                            statusMessage = "Session photo removed."
                        } label: {
                            Image(systemName: "trash")
                                .iconButtonStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }

                SessionPhotoPreview(url: session.sessionPhotoURL)

                HStack(spacing: 10) {
                    Button { showingCamera = true } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .secondaryButtonStyle()
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(session.sessionPhotoURL == nil ? "Upload" : "Replace", systemImage: "photo.fill")
                            .secondaryButtonStyle()
                    }
                    .buttonStyle(.plain)
                }

                if statusMessage.isEmpty == false {
                    Text(statusMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.cutAccent)
                }
            }
        }
    }

    private func shareCardActions(_ session: WorkoutSession) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Share card")
                    .sectionTitle()

                if let image = shareCardPreviewImage(for: session) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                } else {
                    Text("Attach a session photo to generate a premium vertical progress card.")
                        .foregroundStyle(Color.secondaryText)
                }

                Button { createShareCard(session) } label: {
                    Label("Create Share Card", systemImage: "sparkles")
                        .primaryButtonStyle()
                }
                .buttonStyle(.plain)
                .disabled(session.sessionPhotoURL == nil)

                HStack(spacing: 10) {
                    Button { saveGeneratedCard(session) } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down.fill")
                            .secondaryButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .disabled(activeShareURL(for: session) == nil)

                    Button { shareGeneratedCard(session) } label: {
                        Label("Share", systemImage: "square.and.arrow.up.fill")
                            .secondaryButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .disabled(activeShareURL(for: session) == nil)
                }

                Button { shareToInstagramStory(session) } label: {
                    Label("Share to Instagram Story", systemImage: "camera.fill")
                        .secondaryButtonStyle()
                }
                .buttonStyle(.plain)
                .disabled(activeShareURL(for: session) == nil)
            }
        }
    }

    private func recommendationsCard(_ session: WorkoutSession) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Next time")
                    .sectionTitle()
                ForEach(session.exerciseLogs) { log in
                    Text("\(log.exerciseName): \(store.recommendation(for: log))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
    }

    @MainActor
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        store.attachSessionPhoto(image, to: sessionID)
        selectedPhotoItem = nil
        statusMessage = "Session photo attached."
    }

    private func createShareCard(_ session: WorkoutSession) {
        guard let image = renderShareCard(for: session),
              let url = store.updateShareCard(for: session.id, image: image, template: .fullPhotoHero)
        else {
            statusMessage = "Add a session photo first."
            return
        }

        shareCardURL = url
        statusMessage = "Share card created."
    }

    private func saveGeneratedCard(_ session: WorkoutSession) {
        guard let url = activeShareURL(for: session),
              let image = UIImage(contentsOfFile: url.path)
        else {
            statusMessage = "Create a share card first."
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        statusMessage = "Saved to Photos."
    }

    private func shareGeneratedCard(_ session: WorkoutSession) {
        guard let url = activeShareURL(for: session) else {
            statusMessage = "Create a share card first."
            return
        }

        store.markSessionShared(session.id)
        sharingItems = [url]
        showingShareSheet = true
    }

    private func shareToInstagramStory(_ session: WorkoutSession) {
        guard let url = activeShareURL(for: session),
              let image = UIImage(contentsOfFile: url.path),
              let imageData = image.pngData()
        else {
            statusMessage = "Create a share card first."
            return
        }

        guard let instagramURL = URL(string: "instagram-stories://share"),
              UIApplication.shared.canOpenURL(instagramURL)
        else {
            statusMessage = "Instagram is not installed on this device."
            return
        }

        let pasteboardItems: [[String: Any]] = [
            [
                "com.instagram.sharedSticker.backgroundImage": imageData,
                "com.instagram.sharedSticker.appID": "com.vpanev.gymcuttracker"
            ]
        ]
        let options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(300)
        ]

        UIPasteboard.general.setItems(pasteboardItems, options: options)
        store.markSessionShared(session.id)
        UIApplication.shared.open(instagramURL)
        statusMessage = "Opening Instagram Story."
    }

    private func activeShareURL(for session: WorkoutSession) -> URL? {
        shareCardURL ?? session.generatedShareCardURL
    }

    private func shareCardPreviewImage(for session: WorkoutSession) -> UIImage? {
        guard let url = activeShareURL(for: session) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private func renderShareCard(for session: WorkoutSession) -> UIImage? {
        guard let photoURL = session.sessionPhotoURL,
              let photo = UIImage(contentsOfFile: photoURL.path)
        else { return nil }

        let renderer = ImageRenderer(
            content: SessionShareCardView(session: session, photo: photo)
                .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1
        return renderer.uiImage
    }
}

private struct SessionPhotoPreview: View {
    let url: URL?

    var body: some View {
        Group {
            if let url, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.cutAccent)
                    Text("Add one photo from this session.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .background(Color.tileFill)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct AppleMusicPermissionCard: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "music.note.house.fill")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color.cutAccent)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.black))
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                }

                Button(action: action) {
                    Label(buttonTitle, systemImage: "music.note")
                        .primaryButtonStyle()
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MusicResultRow: View {
    @EnvironmentObject private var store: FitnessStore
    @EnvironmentObject private var music: AppleMusicManager
    let result: WorkoutMusicSearchResult
    let selectedDay: TrainingDay

    var body: some View {
        HStack(spacing: 12) {
            MusicArtworkView(url: result.artworkURL, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(result.title)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
                    Text(result.musicItemType.title.uppercased())
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.cutAccent)
                }

                Text(result.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                let selection = WorkoutMusicSelection(
                    workoutDayId: selectedDay,
                    musicItemId: result.musicItemId,
                    musicItemType: result.musicItemType,
                    source: result.source,
                    title: result.title,
                    subtitle: result.subtitle,
                    artworkURL: result.artworkURL
                )
                store.saveMusicSelection(selection)
                Task { await music.play(selection: selection) }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.cutAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct WorkoutMusicPlayerCard: View {
    @EnvironmentObject private var store: FitnessStore
    @EnvironmentObject private var music: AppleMusicManager
    let workoutDay: TrainingDay?

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    MusicArtworkView(url: displayArtworkURL, size: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout Music")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.cutAccent)
                        Text(displayTitle)
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                        Text(displaySubtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 14) {
                        Button {
                            Task { await music.skipToPrevious() }
                        } label: {
                            Image(systemName: "backward.fill")
                        }
                        .disabled(music.hasPlayableQueue == false)

                        Button {
                            Task { await playOrToggle() }
                        } label: {
                            Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                        }
                        .disabled(savedSelection == nil && music.hasPlayableQueue == false)

                        Button {
                            Task { await music.skipToNext() }
                        } label: {
                            Image(systemName: "forward.fill")
                        }
                        .disabled(music.hasPlayableQueue == false)
                    }
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.cutAccent)
                    .buttonStyle(.plain)
                }

                if let message = music.errorMessage {
                    Text(message)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.orange)
                        .lineLimit(2)
                } else if savedSelection == nil && music.hasPlayableQueue == false {
                    Text("Choose music in the Music tab for this workout day.")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
    }

    private var savedSelection: WorkoutMusicSelection? {
        guard let workoutDay else { return nil }
        return store.musicSelection(for: workoutDay)
    }

    private var displayTitle: String {
        if music.hasPlayableQueue || music.isPlaying {
            return music.nowPlayingTitle
        }
        return savedSelection?.title ?? "Not playing"
    }

    private var displaySubtitle: String {
        if music.hasPlayableQueue || music.isPlaying {
            return music.nowPlayingSubtitle
        }
        if let savedSelection {
            return "\(savedSelection.musicItemType.title) • \(savedSelection.subtitle)"
        }
        return "Apple Music"
    }

    private var displayArtworkURL: URL? {
        if music.hasPlayableQueue || music.isPlaying {
            return music.nowPlayingArtworkURL
        }
        return savedSelection?.artworkURL
    }

    private func playOrToggle() async {
        if music.hasPlayableQueue {
            await music.togglePlayback()
        } else if let savedSelection {
            await music.play(selection: savedSelection)
        }
    }
}

private struct ExpandedMusicPlayerSheet: View {
    @EnvironmentObject private var music: AppleMusicManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.cutBlack.ignoresSafeArea()

            VStack(spacing: 22) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 5)

                MusicArtworkView(url: music.nowPlayingArtworkURL, size: 220)
                    .shadow(color: Color.cutAccent.opacity(0.22), radius: 28, x: 0, y: 18)

                VStack(spacing: 6) {
                    Text(music.nowPlayingTitle)
                        .font(.title2.weight(.black))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(music.nowPlayingSubtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }

                ProgressView(value: music.isPlaying ? 0.45 : 0.05)
                    .tint(Color.cutAccent)

                HStack(spacing: 34) {
                    Button {
                        Task { await music.skipToPrevious() }
                    } label: {
                        Image(systemName: "backward.fill")
                    }

                    Button {
                        Task { await music.togglePlayback() }
                    } label: {
                        Image(systemName: music.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 58, weight: .black))
                    }

                    Button {
                        Task { await music.skipToNext() }
                    } label: {
                        Image(systemName: "forward.fill")
                    }
                }
                .font(.title2.weight(.black))
                .foregroundStyle(Color.cutAccent)
                .buttonStyle(.plain)

                HStack(spacing: 12) {
                    Button {
                        music.stop()
                    } label: {
                        Label("Stop Music", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.red)

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.cutAccent)
                }
            }
            .padding(24)
        }
    }
}

private struct MusicArtworkView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: max(size * 0.18, 10), style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: [Color.cutAccent.opacity(0.8), Color.blue.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
                .font(.title2.weight(.black))
                .foregroundStyle(.black.opacity(0.78))
        }
    }
}

private struct EmptyMusicState: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}

private struct SessionShareCardView: View {
    let session: WorkoutSession
    let photo: UIImage

    var body: some View {
        ZStack {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 1080, height: 1920)
                .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.40),
                    Color.black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [Color.cutAccent.opacity(0.26), Color.clear, Color.neonBlue.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 16) {
                        DumbbellLogoMark(size: 62)
                        Text("Gym Cut Tracker")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(session.date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 22) {
                    Text("Workout Complete")
                        .font(.system(size: 76, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(session.day.rawValue) - Full body workout")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cutAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    HStack(spacing: 18) {
                        ShareCardStat(title: "Duration", value: session.formattedDuration)
                        ShareCardStat(title: "Exercises", value: "\(session.exerciseLogs.count)")
                        ShareCardStat(title: "Sets", value: "\(session.completedSets)")
                    }

                    Text("\"\(session.motivationalQuote ?? MotivationalQuoteLibrary.fallback)\"")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.cutAccent)
                        .shadow(color: Color.cutAccent.opacity(0.85), radius: 8, x: 0, y: 0)
                        .shadow(color: Color.cutAccent.opacity(0.42), radius: 18, x: 0, y: 0)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                .padding(34)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 2)
                )
            }
            .padding(66)
        }
        .frame(width: 1080, height: 1920)
        .background(Color.black)
    }
}

private struct DumbbellLogoMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(Color.black.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .stroke(Color.cutAccent.opacity(0.32), lineWidth: max(1, size * 0.035))
                )

            Circle()
                .fill(Color.cutAccent.opacity(0.18))
                .blur(radius: size * 0.09)
                .frame(width: size * 0.74, height: size * 0.74)

            Image(systemName: "dumbbell.fill")
                .font(.system(size: size * 0.48, weight: .black))
                .foregroundStyle(Color.cutAccent)
                .rotationEffect(.degrees(-10))
                .shadow(color: Color.cutAccent.opacity(0.55), radius: size * 0.10)
        }
        .frame(width: size, height: size)
    }
}

private struct ShareCardStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension WorkoutSession {
    var completedSets: Int {
        exerciseLogs.flatMap(\.setLogs).filter(\.completed).count
    }

    var totalVolume: Double {
        exerciseLogs.flatMap(\.setLogs).filter(\.completed).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}

private struct ProgressRow: View {
    let progress: ExerciseProgress

    var body: some View {
        PremiumCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(progress.exercise.name)
                        .font(.headline.weight(.bold))
                    Text("Last: \(progress.lastSetSummary) - Best: \(progress.bestWeight.clean) kg")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                }
                Spacer()
                Text(progress.trend.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(progress.trend == .dropping ? .orange : Color.cutAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.tileFill, in: Capsule())
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .metricLabel()
            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(16)
        .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ActivityHeroCard: View {
    let title: String
    let subtitle: String
    let summary: ActivitySummary

    var body: some View {
        PremiumCard {
            HStack(spacing: 18) {
                ActivityRing(percentage: summary.percentage)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.bold))
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                    Text("\(summary.completedCount) of \(summary.scheduledCount) completed")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.cutAccent)
                    Text(summary.remainingCount == 0 ? "Training target complete." : "\(summary.remainingCount) sessions remaining.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct ActivityPercentBadge: View {
    let title: String
    let summary: ActivitySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .metricLabel()
                Spacer()
                Text("\(summary.percentage)%")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.cutAccent)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(Color.cutAccent.gradient)
                        .frame(width: max(10, geometry.size.width * CGFloat(summary.percentage) / 100))
                }
            }
            .frame(height: 10)

            Text("\(summary.completedCount)/\(summary.scheduledCount) sessions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(14)
        .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ActivityRing: View {
    let percentage: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 12)

            Circle()
                .trim(from: 0, to: CGFloat(percentage) / 100)
                .stroke(
                    AngularGradient(colors: [Color.cutAccent, Color.neonBlue, Color.cutAccent], center: .center),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(percentage)%")
                    .font(.title2.weight(.black))
                Text("done")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .frame(width: 94, height: 94)
    }
}

private struct MonthDayCell: View {
    let item: TrainingCalendarDay
    var session: WorkoutSession?

    var body: some View {
        VStack(spacing: 5) {
            Text(item.date.formatted(.dateTime.day()))
                .font(.caption.weight(.black))

            if let trainingDay = item.trainingDay {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.completed ? Color.cutAccent : Color.neonBlue.opacity(0.85))
                    .accessibilityLabel(item.completed ? "\(trainingDay.rawValue) completed" : "\(trainingDay.rawValue) planned")
            } else {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 6, height: 6)
            }

            if let weight = session?.bodyWeightKg {
                Text("\(weight.clean)kg")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color.cutAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(item.isInDisplayedMonth ? Color.white : Color.white.opacity(0.25))
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(cellBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var cellBackground: Color {
        if item.completed { return Color.cutAccent.opacity(0.16) }
        if item.trainingDay != nil { return Color.neonBlue.opacity(0.13) }
        return Color.tileFill
    }
}

private struct CalendarStatusIcon: View {
    let completed: Bool
    let scheduled: Bool

    var body: some View {
        Image(systemName: completed ? "checkmark.circle.fill" : "circle")
            .font(.title2.weight(.bold))
            .foregroundStyle(completed ? Color.cutAccent : (scheduled ? Color.neonBlue : Color.secondaryText))
            .frame(width: 38, height: 38)
            .background(Color.tileFill, in: Circle())
    }
}

private struct LegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum ActivityScope: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

private struct MiniBarChart: View {
    let points: [Double]

    var body: some View {
        let maxPoint = max(points.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.cutAccent.gradient)
                    .frame(height: max(12, 120 * (point / maxPoint)))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .bottom)
        .padding(.top, 8)
    }
}

private struct MeasurementStepper: View {
    let title: String
    @Binding var value: Double
    let suffix: String
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 6)

            HStack(spacing: 6) {
                TextField("0", value: clampedValue, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.title3.monospacedDigit().weight(.black))
                    .foregroundStyle(Color.cutAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(minWidth: 76, maxWidth: 92, alignment: .trailing)

                Text(suffix)
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.cutAccent)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(width: 144, alignment: .trailing)
            .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .layoutPriority(1)

            HStack(spacing: 0) {
                Button {
                    adjust(by: -step)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 42, height: 42)
                }
                .disabled(value <= range.lowerBound)

                Divider()
                    .frame(height: 28)
                    .overlay(Color.white.opacity(0.20))

                Button {
                    adjust(by: step)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 42, height: 42)
                }
                .disabled(value >= range.upperBound)
            }
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .background(Color.white.opacity(0.10), in: Capsule())
            .buttonStyle(.plain)
        }
    }

    private var clampedValue: Binding<Double> {
        Binding {
            value
        } set: { newValue in
            value = min(max(newValue, range.lowerBound), range.upperBound)
        }
    }

    private func adjust(by amount: Double) {
        value = min(max(value + amount, range.lowerBound), range.upperBound)
    }
}

private struct RuleRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.cutAccent)
                .frame(width: 30, height: 30)
                .background(Color.cutAccent.opacity(0.12), in: Circle())
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
            Spacer()
        }
    }
}

private struct NumberField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        TextField(title, value: $value, format: .number.precision(.fractionLength(0...1)))
            .keyboardType(.decimalPad)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(10)
            .frame(width: 78)
            .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.secondaryText)
                    .padding(5)
            }
    }
}

private struct IntField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        TextField(title, value: $value, format: .number)
            .keyboardType(.numberPad)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(10)
            .frame(width: 72)
            .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.secondaryText)
                    .padding(5)
            }
    }
}

private struct PremiumScreen<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cutBlack.ignoresSafeArea()
                LinearGradient(
                    colors: [Color.cutAccent.opacity(0.18), Color.clear, Color.neonBlue.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(subtitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                        content
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbarBackground(Color.cutBlack, for: .navigationBar)
        }
    }
}

private struct PremiumCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 12)
    }
}

private extension View {
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    func primaryButtonStyle() -> some View {
        self
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.cutAccent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }

    func iconButtonStyle() -> some View {
        self
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.cutAccent)
            .frame(width: 42, height: 42)
            .background(Color.cutAccent.opacity(0.12), in: Circle())
    }

    func sectionTitle() -> some View {
        self
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
    }

    func metricLabel() -> some View {
        self
            .font(.caption.weight(.black))
            .foregroundStyle(Color.secondaryText)
    }
}

private extension Color {
    static var cutBlack: Color { Color(red: 0.02, green: 0.025, blue: 0.03) }
    static var cardFill: Color { Color(red: 0.075, green: 0.08, blue: 0.09) }
    static var tileFill: Color { Color.white.opacity(0.055) }
    static var cutAccent: Color { Color(red: 0.31, green: 1.0, blue: 0.42) }
    static var neonBlue: Color { Color(red: 0.15, green: 0.58, blue: 1.0) }
    static var secondaryText: Color { Color.white.opacity(0.64) }
}

#Preview {
    ContentView()
        .environmentObject(FitnessStore())
}
