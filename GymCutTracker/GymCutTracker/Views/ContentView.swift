import SwiftUI
import PhotosUI

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

            BodyView()
                .tabItem { Label("Body", systemImage: "person.crop.rectangle.stack") }

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

    private var todayCard: some View {
        let workout = store.todayWorkout
        return PremiumCard {
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
                    Text("\(last.exerciseLogs.count) exercises, \(last.exerciseLogs.flatMap(\.setLogs).filter(\.completed).count) completed sets, \(sessionVolume(last).clean) kg volume")
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
                        HStack(spacing: 12) {
                            CalendarStatusIcon(completed: item.completed, scheduled: item.trainingDay != nil)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.trainingDay?.rawValue ?? "Training")
                                    .font(.headline.weight(.bold))
                                Text(item.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.secondaryText)
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
                }
            }
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
                            MonthDayCell(item: item)
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
    @Environment(\.dismiss) private var dismiss
    let day: TrainingDay

    @State private var logs: [ExerciseLog] = []
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var showingSummary = false
    @State private var savedSession: WorkoutSession?

    var body: some View {
        PremiumScreen(title: store.workout(for: day).title, subtitle: "Log each set, then finish") {
            VStack(spacing: 16) {
                ForEach($logs) { $log in
                    ExerciseLogCard(log: $log)
                }

                PremiumCard {
                    TextField("Workout notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                }

                Button { finishWorkout() } label: {
                    Label("Finish Workout", systemImage: "checkmark.circle.fill")
                        .primaryButtonStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear(perform: buildLogsIfNeeded)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSummary) {
            if let savedSession {
                WorkoutSummaryView(sessionID: savedSession.id)
            }
        }
    }

    private func buildLogsIfNeeded() {
        guard logs.isEmpty else { return }
        startDate = .now
        logs = store.workout(for: day).exercises.map { exercise in
            ExerciseLog(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                muscleGroup: exercise.muscleGroup,
                targetReps: exercise.targetReps,
                setLogs: (1...exercise.sets).map { SetLog(setNumber: $0) }
            )
        }
    }

    private func finishWorkout() {
        let duration = max(Int(Date().timeIntervalSince(startDate) / 60), 1)
        let session = WorkoutSession(day: day, exerciseLogs: logs, durationMinutes: duration, notes: notes)
        store.saveSession(session)
        savedSession = store.lastWorkout
        showingSummary = true
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

struct BodyView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var weight = 86.0
    @State private var waist = 92.0
    @State private var goal = 80.0
    @State private var notes = ""

    var body: some View {
        PremiumScreen(title: "Body", subtitle: "Scale, measurements, weekly check-ins") {
            VStack(spacing: 16) {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New check-in")
                            .sectionTitle()
                        MeasurementStepper(title: "Weight", value: $weight, suffix: "kg", range: 40...180, step: 0.1)
                        MeasurementStepper(title: "Waist", value: $waist, suffix: "cm", range: 40...180, step: 0.5)
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
                        Text("Progress photos are modeled and ready for the next iteration; this MVP focuses on body weight and measurements.")
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
            waist = store.sortedBodyEntries.first?.waistCm ?? 92
        }
    }

    private func saveBodyEntry() {
        store.addBodyEntry(BodyProgress(weightKg: weight, waistCm: waist, goalWeightKg: goal, notes: notes))
        notes = ""
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: FitnessStore

    var body: some View {
        PremiumScreen(title: "Settings", subtitle: "Program rules and cut targets") {
            VStack(spacing: 16) {
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

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var shareCardURL: URL?
    @State private var sharingItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var statusMessage = ""

    private var session: WorkoutSession? {
        store.session(id: sessionID)
    }

    var body: some View {
        Group {
            if let session {
                PremiumScreen(title: "Workout Saved", subtitle: session.day.rawValue) {
                    VStack(spacing: 16) {
                        summaryGrid(session)
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
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                store.attachSessionPhoto(image, to: sessionID)
                statusMessage = "Session photo attached."
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: sharingItems)
        }
    }

    private func summaryGrid(_ session: WorkoutSession) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Duration", value: "\(session.durationMinutes) min", detail: "session")
            MetricTile(title: "Volume", value: "\(session.totalVolume.clean) kg", detail: "total")
            MetricTile(title: "Exercises", value: "\(session.exerciseLogs.count)", detail: "completed")
            MetricTile(title: "Sets", value: "\(session.completedSets)", detail: "completed")
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

                    Text("\(session.day.rawValue) - \(session.day.programTitle)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cutAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    HStack(spacing: 18) {
                        ShareCardStat(title: "Duration", value: "\(session.durationMinutes)m")
                        ShareCardStat(title: "Volume", value: "\(session.totalVolume.clean) kg")
                    }

                    HStack(spacing: 18) {
                        ShareCardStat(title: "Exercises", value: "\(session.exerciseLogs.count)")
                        ShareCardStat(title: "Sets", value: "\(session.completedSets)")
                    }

                    if session.personalRecords.isEmpty == false {
                        Text("PR \(session.personalRecords.joined(separator: " / "))")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.cutAccent, in: Capsule())
                    }
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
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.clean) \(suffix)")
                    .foregroundStyle(Color.cutAccent)
            }
            .font(.headline.weight(.semibold))
        }
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
