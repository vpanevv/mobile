import SwiftData
import SwiftUI

struct GarageView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("MyGarageMate.didCompleteGarageOnboarding") private var didCompleteGarageOnboarding = false
    let profile: UserProfile

    @StateObject private var viewModel = GarageViewModel()
    @State private var isAddingCar = false
    @State private var carPendingDeletion: Car?
    @State private var reminderTargetCar: Car?
    @Namespace private var cardNamespace

    private var cars: [Car] {
        viewModel.sortedCars(for: profile)
    }

    private var onboardingStep: GarageOnboardingStep? {
        guard !didCompleteGarageOnboarding else { return nil }
        if cars.isEmpty { return .addCar }
        if cars.allSatisfy({ $0.reminders.isEmpty }) { return .addReminder }
        return .complete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let onboardingStep {
                        GarageOnboardingCard(step: onboardingStep) {
                            perform(onboardingStep)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, cars.isEmpty ? 30 : 12)
                        .padding(.bottom, cars.isEmpty ? 4 : 12)
                    }

                    if cars.isEmpty {
                        EmptyStateView(
                            symbolName: "car.2.fill",
                            title: "Add your first car",
                            message: "Track services, repairs, maintenance and reminders in one place."
                        )
                        .padding(.horizontal)
                        .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(cars) { car in
                                NavigationLink {
                                    CarDetailView(car: car, profile: profile)
                                        .navigationTransition(.zoom(sourceID: car.id, in: cardNamespace))
                                } label: {
                                    CarCardView(car: car, profile: profile)
                                }
                                .buttonStyle(CardPressStyle())
                                .matchedTransitionSource(id: car.id, in: cardNamespace)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        carPendingDeletion = car
                                    } label: {
                                        Label("Delete Car", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
                .padding(.bottom, Theme.Spacing.s)
            }
            .scrollContentBackground(.hidden)
            .background(AmbientBackground())
            .safeAreaInset(edge: .bottom) {
                addCarBar
            }
            .navigationTitle("My Garage")
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
            .sheet(
                isPresented: Binding(
                    get: { reminderTargetCar != nil },
                    set: { if !$0 { reminderTargetCar = nil } }
                )
            ) {
                if let reminderTargetCar {
                    AddReminderView(car: reminderTargetCar)
                }
            }
            .confirmationDialog(
                "Delete this car?",
                isPresented: Binding(
                    get: { carPendingDeletion != nil },
                    set: { if !$0 { carPendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Car", role: .destructive) {
                    deletePendingCar()
                }
                Button("Cancel", role: .cancel) {
                    carPendingDeletion = nil
                }
            } message: {
                Text("This removes the car and all related service records, reminders, and mechanic notes from this device.")
            }
        }
    }

    private func perform(_ step: GarageOnboardingStep) {
        HapticsManager.lightTap()

        switch step {
        case .addCar:
            isAddingCar = true
        case .addReminder:
            reminderTargetCar = cars.first
        case .complete:
            didCompleteGarageOnboarding = true
            HapticsManager.success()
        }
    }

    private var addCarBar: some View {
        addCarCTA
            .padding(.horizontal, 32)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.s)
            .frame(maxWidth: .infinity)
    }

    private var addCarCTA: some View {
        Button {
            HapticsManager.lightTap()
            isAddingCar = true
        } label: {
            Label("Add Car", systemImage: "plus")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 172)
                .frame(height: 54)
                .padding(.horizontal, 10)
                .background(Color.accentColor, in: Capsule())
                .shadow(color: Color.accentColor.opacity(0.26), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(AddCarCTAButtonStyle())
        .accessibilityLabel("Add Car")
        .accessibilityHint("Opens the add car form")
    }

    private func deletePendingCar() {
        guard let car = carPendingDeletion else { return }
        for reminder in car.reminders {
            NotificationManager.cancel(reminder: reminder)
        }
        modelContext.delete(car)

        do {
            try modelContext.save()
            HapticsManager.warning()
        } catch {
            assertionFailure("Failed to delete car: \(error)")
        }

        carPendingDeletion = nil
    }
}

private struct AddCarCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Press style for hero cards: a gentle spring scale that feels tactile.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

private enum GarageOnboardingStep {
    case addCar
    case addReminder
    case complete

    var symbolName: String {
        switch self {
        case .addCar: "car.2.fill"
        case .addReminder: "bell.badge.fill"
        case .complete: "checkmark.seal.fill"
        }
    }

    var title: String {
        switch self {
        case .addCar: "Add your first car"
        case .addReminder: "Add your first reminder"
        case .complete: "You're set"
        }
    }

    var message: String {
        switch self {
        case .addCar:
            "Start with the car you drive most. Services, reminders, and costs will live under it."
        case .addReminder:
            "Set one upcoming reminder for oil, inspection, insurance, or anything custom."
        case .complete:
            "Your garage now has a car and a reminder. Keep building its service story over time."
        }
    }

    var buttonTitle: String {
        switch self {
        case .addCar: "Add Car"
        case .addReminder: "Add Reminder"
        case .complete: "Done"
        }
    }
}

private struct GarageOnboardingCard: View {
    let step: GarageOnboardingStep
    let action: () -> Void

    var body: some View {
        GlassCardView(cornerRadius: 24) {
            HStack(spacing: 14) {
                Image(systemName: step.symbolName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor.gradient, in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(step.title)
                        .font(.headline)
                    Text(step.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 8)

                Button(action: action) {
                    Text(step.buttonTitle)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
