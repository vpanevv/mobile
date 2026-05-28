import SwiftUI
import SwiftData
import UIKit

// MARK: - PeopleView

struct PeopleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query private var allPeople: [Person]

    @State private var showAdd     = false
    @State private var editTarget: Person? = nil
    @State private var appeared    = false

    // Sort by daysUntil (soonest first) — computed after fetch
    private var sortedPeople: [Person] {
        allPeople.sorted { $0.daysUntil < $1.daysUntil }
    }

    var body: some View {
        ZStack {
            // Background
            NeuralBackground()

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("People")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xc084fc))
                            .frame(width: 34, height: 34)
                            .background(Color(hex: 0xc084fc).opacity(0.12))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(hex: 0xc084fc).opacity(0.30), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // ── Content ──────────────────────────────────────────
                if sortedPeople.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(sortedPeople.enumerated()), id: \.element.id) { idx, person in
                                PersonCard(
                                    person: person,
                                    onEdit: { editTarget = person },
                                    onDelete: { deletePerson(person) },
                                    onGenerateNow: { generateNow(for: person) }
                                )
                                .padding(.horizontal, 20)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.75)
                                        .delay(Double(idx) * 0.06),
                                    value: appeared
                                )
                            }
                        }
                        .padding(.vertical, 4)

                        // Privacy footer
                        HStack(spacing: 5) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Your people stay private on this device.")
                                .font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(.secondary.opacity(0.45))
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { appeared = true }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPersonView()
                .environment(\.modelContext, context)
        }
        .sheet(item: $editTarget) { person in
            AddPersonView(editingPerson: person)
                .environment(\.modelContext, context)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(32)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color(hex: 0xc084fc).opacity(0.6))
            Text("No one added yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text("Add people to get reminders\nfor their special days.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAdd = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Someone")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color(hex: 0xc084fc))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: 0xc084fc).opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: 0xc084fc).opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Actions

    private func deletePerson(_ person: Person) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        ReminderManager.shared.cancelReminder(for: person)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            context.delete(person)
        }
    }

    private func generateNow(for person: Person) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            AppRouter.shared.pendingWish = AppRouter.PendingWish(
                name: person.name,
                occasion: person.occasion
            )
        }
    }
}
