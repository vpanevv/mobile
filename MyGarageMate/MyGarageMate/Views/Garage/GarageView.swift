import SwiftData
import SwiftUI

struct GarageView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile

    @StateObject private var viewModel = GarageViewModel()
    @State private var isAddingCar = false
    @State private var carPendingDeletion: Car?
    @State private var isAddCarCTAVisible = false

    private var cars: [Car] {
        viewModel.sortedCars(for: profile)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        if cars.isEmpty {
                            EmptyStateView(
                                symbolName: "car.2.fill",
                                title: "Add your first car",
                                message: "Track services, repairs, maintenance and reminders in one place."
                            )
                            .padding(.horizontal)
                            .padding(.top, 80)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(cars) { car in
                                    NavigationLink {
                                        CarDetailView(car: car, profile: profile)
                                    } label: {
                                        CarCardView(car: car)
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        Spacer(minLength: cars.isEmpty ? 28 : 140)

                        addCarCTA
                            .padding(.horizontal, 32)
                            .padding(.bottom, cars.isEmpty ? 120 : 132)
                            .opacity(isAddCarCTAVisible ? 1 : 0)
                            .offset(y: isAddCarCTAVisible ? 0 : 8)
                    }
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My garage")
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) {
                    isAddCarCTAVisible = true
                }
            }
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
