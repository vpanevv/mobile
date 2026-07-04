import SwiftData
import SwiftUI
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile
    @Binding var selection: AppTab

    @Query(sort: \Car.createdAt, order: .forward) private var cars: [Car]
    @StateObject private var weather = WeatherViewModel()
    @State private var isAddingCar = false
    @State private var appeared = false
    @Namespace private var heroNamespace

    private var upcoming: [(reminder: CarReminder, car: Car)] {
        cars.flatMap { car in
            car.upcomingReminders.map { (reminder: $0, car: car) }
        }
        .sorted { CarReminder.sortUpcoming($0.reminder, $1.reminder) }
    }

    private var nextUp: (reminder: CarReminder, car: Car)? { upcoming.first }

    private var totalThisYear: Int {
        cars.reduce(0) { $0 + $1.totalSpentThisYear(currencyCode: profile.preferredCurrencyCode) }
    }

    private var focusAccent: Color { nextUp?.car.accentColor ?? Theme.accent }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    header
                        .entrance(appeared, index: 0)

                    WeatherCardView(viewModel: weather)
                        .entrance(appeared, index: 1)

                    if cars.isEmpty {
                        emptyGarage
                    } else {
                        nextUpSection
                            .entrance(appeared, index: 2)
                        quickActions
                            .entrance(appeared, index: 3)
                        garageStrip
                            .entrance(appeared, index: 4)
                        statsRow
                            .entrance(appeared, index: 5)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .scrollContentBackground(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background(AmbientBackground(tint: focusAccent))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.lightTap()
                        isAddingCar = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add car")
                }
            }
            .sheet(isPresented: $isAddingCar) {
                AddCarView(profile: profile)
            }
            .task { await weather.loadIfNeeded() }
            .onAppear {
                withAnimation { appeared = true }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.s)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let base: String
        switch hour {
        case 5..<12: base = "Good morning"
        case 12..<17: base = "Good afternoon"
        case 17..<22: base = "Good evening"
        default: base = "Good night"
        }
        let firstName = profile.name.split(separator: " ").first.map(String.init)
        if let firstName, !firstName.isEmpty, firstName != "MyGarageMate" {
            return "\(base), \(firstName)"
        }
        return base
    }

    // MARK: Next up

    @ViewBuilder
    private var nextUpSection: some View {
        if let nextUp {
            NavigationLink {
                CarDetailView(car: nextUp.car, profile: profile)
                    .navigationTransition(.zoom(sourceID: "hero-\(nextUp.car.id)", in: heroNamespace))
            } label: {
                NextUpHeroCard(reminder: nextUp.reminder, car: nextUp.car)
            }
            .buttonStyle(CardPressStyle())
            .matchedTransitionSource(id: "hero-\(nextUp.car.id)", in: heroNamespace)
        } else {
            allClearCard
        }
    }

    private var allClearCard: some View {
        HStack(spacing: Theme.Spacing.l) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 34))
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 3) {
                Text("All clear")
                    .font(.title3.weight(.bold))
                Text("No service due across your garage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .metallicStroke(cornerRadius: Theme.Radius.card)
    }

    // MARK: Quick actions

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.m) {
            quickAction(title: "Add Car", symbol: "plus.circle.fill", tint: Theme.accent) {
                HapticsManager.soft()
                isAddingCar = true
            }
            quickAction(title: "All Cars", symbol: "car.2.fill", tint: Theme.mist) {
                HapticsManager.soft()
                selection = .garage
            }
            quickAction(title: "Reminders", symbol: "bell.badge.fill", tint: Theme.ember) {
                HapticsManager.soft()
                selection = .upcoming
            }
        }
    }

    private func quickAction(title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.l)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .metallicStroke(cornerRadius: Theme.Radius.control)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityLabel(title)
    }

    // MARK: Garage strip

    private var garageStrip: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader("Your garage", systemImage: "car.side.fill") {
                Button("All") { selection = .garage }
                    .font(.subheadline.weight(.semibold))
            }

            ScrollView(.horizontal) {
                HStack(spacing: Theme.Spacing.m) {
                    ForEach(cars) { car in
                        NavigationLink {
                            CarDetailView(car: car, profile: profile)
                                .navigationTransition(.zoom(sourceID: "strip-\(car.id)", in: heroNamespace))
                        } label: {
                            GarageStripCard(car: car)
                        }
                        .buttonStyle(CardPressStyle())
                        .matchedTransitionSource(id: "strip-\(car.id)", in: heroNamespace)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.m) {
            statTile(value: "\(cars.count)", label: cars.count == 1 ? "Car" : "Cars", symbol: "car.2.fill")
            statTile(
                value: CurrencyFormatter.compactString(fromMinor: totalThisYear, currencyCode: profile.preferredCurrencyCode),
                label: "This year",
                symbol: "creditcard.fill"
            )
            statTile(value: "\(upcoming.count)", label: "Open", symbol: "bell.badge.fill")
        }
    }

    private func statTile(value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(focusAccent)
            Text(value)
                .font(.title3.weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .metallicStroke(cornerRadius: Theme.Radius.control)
    }

    // MARK: Empty

    private var emptyGarage: some View {
        EmptyStateView(
            symbolName: "car.2.fill",
            title: "Add your first car",
            message: "Track services, reminders, and costs across your whole garage.",
            buttonTitle: "Add Car",
            action: { isAddingCar = true }
        )
    }
}
