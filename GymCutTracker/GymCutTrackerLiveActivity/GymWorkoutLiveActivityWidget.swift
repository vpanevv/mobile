import ActivityKit
import SwiftUI
import WidgetKit

struct GymWorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymWorkoutActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.gymBlack)
                .activitySystemActionForegroundColor(Color.gymGreen)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandMetricView(
                        label: "SET",
                        value: "\(context.state.currentSetNumber)/\(context.state.totalSetsForExercise)",
                        alignment: .leading
                    )
                }

                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandMetricView(
                        label: context.state.isResting ? "REST" : "TIME",
                        value: dynamicIslandTimerText(context.state),
                        alignment: .trailing
                    )
                }

                DynamicIslandExpandedRegion(.center) {
                    DynamicIslandExpandedCenterView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    DynamicIslandExpandedStatsView(context: context)
                }
            } compactLeading: {
                DynamicIslandCompactLeadingView(context: context)
            } compactTrailing: {
                DynamicIslandCompactTrailingView(context: context)
            } minimal: {
                DynamicIslandMinimalView(context: context)
            }
            .keylineTint(Color.gymGreen)
        }
        .configurationDisplayName("Gym Cut Tracker")
        .description("Shows your active gym session on the Lock Screen and Dynamic Island.")
    }

    private func dynamicIslandTimerText(_ state: GymWorkoutActivityAttributes.ContentState) -> String {
        if state.isResting {
            return restText(state)
        }
        return formatDuration(Int(state.workoutDuration))
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<GymWorkoutActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            exerciseRow
            statsRow
            bottomStatus
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            LogoMark()

            VStack(alignment: .leading, spacing: 2) {
                Text("Gym Cut Tracker")
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)

                Text("\(context.attributes.workoutDayName) - \(context.attributes.workoutName)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            StatusPillView(text: context.state.isComplete ? "Complete" : (context.state.isPaused ? "Paused" : context.state.statusText))
        }
    }

    private var exerciseRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.currentExerciseName)
                    .font(.headline.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .truncationMode(.tail)

                Text("Set \(context.state.currentSetNumber) of \(context.state.totalSetsForExercise) - Target \(context.state.targetReps) reps")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .truncationMode(.tail)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            timerView
        }
    }

    @ViewBuilder
    private var timerView: some View {
        if context.state.isResting, let restEndTime = context.state.restEndTime {
            Text(timerInterval: Date.now...restEndTime, countsDown: true)
                .font(.headline.monospacedDigit().weight(.black))
                .foregroundStyle(Color.gymGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else if context.state.isComplete {
            Text(formatDuration(Int(context.state.workoutDuration)))
                .font(.headline.monospacedDigit().weight(.black))
                .foregroundStyle(Color.gymGreen)
                .lineLimit(1)
        } else {
            Text(formatDuration(Int(context.state.workoutDuration)))
                .font(.headline.monospacedDigit().weight(.black))
                .foregroundStyle(context.state.isPaused ? Color.orange : Color.gymGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatPillView(label: "Last", value: lastSetText)
            StatPillView(label: "Sets", value: "\(context.state.completedSets)")
            StatPillView(label: "Volume", value: "\(context.state.totalVolume.clean) kg")
        }
    }

    @ViewBuilder
    private var bottomStatus: some View {
        if context.state.isResting, let restEndTime = context.state.restEndTime {
            HStack(spacing: 5) {
                Text("Resting")
                    .foregroundStyle(Color.gymGreen)
                Text("- Next set in")
                    .foregroundStyle(.secondary)
                Text(timerInterval: Date.now...restEndTime, countsDown: true)
                    .foregroundStyle(Color.gymGreen)
            }
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        } else if context.state.isComplete {
            Text("Workout complete - \(context.state.personalRecordCount) PRs")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.gymGreen)
                .lineLimit(1)
        } else if context.state.isPaused {
            Text("Paused")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.orange)
                .lineLimit(1)
        } else {
            Text("Ready for next set")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var lastSetText: String {
        guard context.state.lastSetReps > 0 else { return "--" }
        return "\(context.state.lastSetWeight.clean) x \(context.state.lastSetReps)"
    }
}

private struct DynamicIslandExpandedCenterView: View {
    let context: ActivityViewContext<GymWorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 2) {
            Text(context.state.currentExerciseName)
                .font(.subheadline.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .truncationMode(.tail)

            Text(context.state.isPaused ? "Paused" : context.state.statusText)
                .font(.caption2.weight(.bold))
                .foregroundStyle(context.state.isPaused ? Color.orange : (context.state.isResting ? Color.gymGreen : .secondary))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 4)
    }
}

private struct DynamicIslandExpandedStatsView: View {
    let context: ActivityViewContext<GymWorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 6) {
            IslandStatPillView(text: "\(context.state.completedSets) sets")
            IslandStatPillView(text: "\(context.state.totalVolume.clean) kg")
            IslandStatPillView(text: "Last \(lastSetText)")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var lastSetText: String {
        guard context.state.lastSetReps > 0 else { return "--" }
        return "\(context.state.lastSetWeight.clean)x\(context.state.lastSetReps)"
    }
}

private struct DynamicIslandCompactLeadingView: View {
    let context: ActivityViewContext<GymWorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "dumbbell.fill")
                .font(.caption2.weight(.black))
            Text("\(context.state.currentSetNumber)/\(context.state.totalSetsForExercise)")
                .font(.caption2.monospacedDigit().weight(.black))
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(Color.gymGreen)
        .lineLimit(1)
    }
}

private struct DynamicIslandCompactTrailingView: View {
    let context: ActivityViewContext<GymWorkoutActivityAttributes>

    var body: some View {
        Text(timerText)
            .font(.caption2.monospacedDigit().weight(.black))
            .foregroundStyle(Color.gymGreen)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var timerText: String {
        if context.state.isResting {
            return restText(context.state)
        }
        return formatDuration(Int(context.state.workoutDuration))
    }
}

private struct DynamicIslandMinimalView: View {
    let context: ActivityViewContext<GymWorkoutActivityAttributes>

    var body: some View {
        Text("\(context.state.currentSetNumber)")
            .font(.caption2.monospacedDigit().weight(.black))
            .foregroundStyle(Color.gymGreen)
    }
}

private struct StatPillView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.caption.monospacedDigit().weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StatusPillView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(Color.gymGreen)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.gymGreen.opacity(0.14), in: Capsule())
    }
}

private struct DynamicIslandMetricView: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.monospacedDigit().weight(.black))
                .foregroundStyle(Color.gymGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct IslandStatPillView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.monospacedDigit().weight(.bold))
            .foregroundStyle(.white.opacity(0.86))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08), in: Capsule())
    }
}

private func restText(_ state: GymWorkoutActivityAttributes.ContentState) -> String {
        guard let restEndTime = state.restEndTime else { return "--" }
        let seconds = max(Int(restEndTime.timeIntervalSince(.now)), 0)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
}

private func formatDuration(_ seconds: Int) -> String {
    let safeSeconds = max(seconds, 0)
    let hours = safeSeconds / 3600
    let minutes = (safeSeconds % 3600) / 60
    let seconds = safeSeconds % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    return String(format: "%02d:%02d", minutes, seconds)
}

private struct LogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gymGreen.opacity(0.16))
            Image(systemName: "dumbbell.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(Color.gymGreen)
        }
        .frame(width: 32, height: 32)
    }
}

private extension Color {
    static let gymBlack = Color(red: 0.02, green: 0.025, blue: 0.03)
    static let gymGreen = Color(red: 0.31, green: 1.0, blue: 0.42)
}

private extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
