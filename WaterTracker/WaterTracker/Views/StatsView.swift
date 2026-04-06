import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: HydrationStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.20),
                    Color(red: 0.06, green: 0.20, blue: 0.35),
                    Color(red: 0.10, green: 0.39, blue: 0.56)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    highlightsCard
                    weekCard
                }
                .padding(20)
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Last 7 Days")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                statTile(title: "Streak", value: "\(store.sevenDayStreak) days")
                statTile(title: "Average", value: "\(store.averageDailyIntakeLast7Days) ml")
            }

            statTile(title: "Goals Hit This Week", value: "\(store.goalsHitThisWeek)")
        }
        .padding(24)
        .background(glassCardBackground)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Daily Breakdown")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            ForEach(store.last7DaysSnapshots) { day in
                VStack(spacing: 8) {
                    HStack {
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)

                        Spacer()

                        Text("\(day.intakeML) ml")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.84))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.10))

                            Capsule()
                                .fill(day.hitGoal ? Color.green.opacity(0.85) : Color.blue.opacity(0.85))
                                .frame(width: max(10, geometry.size.width * min(Double(day.intakeML) / Double(max(day.goalML, 1)), 1.0)))
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text(day.hitGoal ? "Goal hit" : "\(max(day.goalML - day.intakeML, 0)) ml left")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.68))

                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .background(glassCardBackground)
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(glassTileBackground)
    }

    private var glassCardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
    }

    private var glassTileBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        StatsView()
            .environmentObject(HydrationStore())
    }
}
