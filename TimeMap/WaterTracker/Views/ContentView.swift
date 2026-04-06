import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: HydrationStore
    @AppStorage("has-seen-onboarding") private var hasSeenOnboarding = false
    @State private var customAmount = 400
    @State private var showingCustomSheet = false

    private let quickAddAmounts = [200, 300, 500, 750]

    var body: some View {
        NavigationStack {
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
                        heroCard
                        quickAddCard
                        historyCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Water Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Daily Goal", selection: $store.dailyGoalML) {
                            Text("1.5 L").tag(1_500)
                            Text("2.0 L").tag(2_000)
                            Text("2.5 L").tag(2_500)
                            Text("3.0 L").tag(3_000)
                        }

                        Button("Reset Today", role: .destructive) {
                            store.resetToday()
                        }

                        Button("Show Onboarding") {
                            hasSeenOnboarding = false
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showingCustomSheet) {
                customSheet
                    .presentationDetents([.fraction(0.32)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(greeting)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 20) {
                ProgressRing(progress: store.progress)

                VStack(alignment: .leading, spacing: 12) {
                    metricBlock(title: "Today", value: "\(store.totalTodayML) ml")
                    metricBlock(title: "Remaining", value: "\(store.remainingML) ml")
                    metricBlock(title: "Streak", value: "\(store.currentStreak) day\(store.currentStreak == 1 ? "" : "s")")
                }

                Spacer(minLength: 0)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Add")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(quickAddAmounts, id: \.self) { amount in
                    Button {
                        store.addWater(amount)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("+\(amount) ml")
                                .font(.headline.weight(.bold))
                            Text(amount >= 500 ? "Big glass" : "Quick sip")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                showingCustomSheet = true
            } label: {
                Label("Custom Amount", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(cardBackground)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            if store.todayEntries.isEmpty {
                Text("No water logged yet. Start with your first glass.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(store.todayEntries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(entry.amountML) ml")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(entry.date.formatted(date: .omitted, time: .shortened))
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white.opacity(0.65))
                        }

                        Spacer()

                        Button(role: .destructive) {
                            if let index = store.todayEntries.firstIndex(of: entry) {
                                store.deleteEntries(at: IndexSet(integer: index))
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.white.opacity(0.82))
                                .padding(10)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .background(cardBackground)
    }

    private var customSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("\(customAmount) ml")
                    .font(.system(size: 40, weight: .bold, design: .rounded))

                Stepper(value: $customAmount, in: 100...1_500, step: 50) {
                    Text("Adjust amount")
                        .font(.headline)
                }

                Button("Add Water") {
                    store.addWater(customAmount)
                    showingCustomSheet = false
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()
            }
            .padding(24)
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func metricBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:
            return "Start early. Stay ahead on hydration."
        case 12..<18:
            return "Keep your energy steady this afternoon."
        default:
            return "Finish the day hydrated."
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.white.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }
}

#Preview {
    ContentView()
        .environmentObject(HydrationStore())
}
