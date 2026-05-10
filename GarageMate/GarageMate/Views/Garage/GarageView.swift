import SwiftUI

struct GarageView: View {
    let profile: UserProfile

    @StateObject private var viewModel = GarageViewModel()
    @State private var isAddingCar = false

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
                        message: "Add your first car and GarageMate will keep service costs, reminders, and mechanic notes close at hand.",
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
        }
    }
}
