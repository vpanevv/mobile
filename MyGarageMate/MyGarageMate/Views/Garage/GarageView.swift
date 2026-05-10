import SwiftData
import SwiftUI

struct GarageView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile

    @StateObject private var viewModel = GarageViewModel()
    @State private var isAddingCar = false
    @State private var carPendingDeletion: Car?

    private var cars: [Car] {
        viewModel.sortedCars(for: profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if cars.isEmpty {
                    EmptyStateView(
                        symbolName: "car.badge.plus",
                        title: "Your garage is ready",
                        message: "Add your first car and MyGarageMate will keep service costs, reminders, and mechanic notes close at hand.",
                        buttonTitle: "Add Car"
                    ) {
                        isAddingCar = true
                    }
                    .padding(.horizontal)
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 18) {
                        ForEach(cars) { car in
                            NavigationLink {
                                CarDetailView(car: car, profile: profile)
                            } label: {
                                CarCardView(car: car, currencyCode: profile.preferredCurrencyCode)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    carPendingDeletion = car
                                } label: {
                                    Label("Delete Car", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Garage")
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
