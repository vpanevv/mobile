import SwiftUI
import SwiftData
import UIKit

// MARK: - PeopleView

struct PeopleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss
    @AppStorage("wishlyai.isDark") private var isDark: Bool = true

    @Query private var allPeople: [Person]

    @State private var showAdd     = false
    @State private var editTarget: Person? = nil
    @State private var appeared    = false
    @State private var addPulse    = false

    private let accent = Color(hex: 0xc084fc)

    // Sorted soonest-first
    private var sortedPeople: [Person] {
        allPeople.sorted { $0.daysUntil < $1.daysUntil }
    }

    private var todayPeople: [Person] { sortedPeople.filter { $0.daysUntil == 0 } }
    private var weekPeople:  [Person] { sortedPeople.filter { (1...7).contains($0.daysUntil) } }
    private var monthPeople: [Person] { sortedPeople.filter { (8...30).contains($0.daysUntil) } }
    private var laterPeople: [Person] { sortedPeople.filter { $0.daysUntil > 30 } }

    private var upcomingThisMonth: Int { sortedPeople.filter { $0.daysUntil <= 30 }.count }

    // Sections in display order (empty ones filtered out)
    private var sections: [(title: String, people: [Person])] {
        [
            ("Today",      todayPeople),
            ("This Week",  weekPeople),
            ("This Month", monthPeople),
            ("Later",      laterPeople),
        ].filter { !$0.people.isEmpty }
    }

    var body: some View {
        ZStack {
            NeuralBackground()
            FlowAmbientLayer()

            VStack(spacing: 0) {
                header

                if sortedPeople.isEmpty {
                    emptyState
                } else {
                    peopleList
                }
            }

            // ── Floating add button (populated list only) ────────────────
            if !sortedPeople.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: 0x9333ea), Color(hex: 0xc084fc)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: accent.opacity(0.45), radius: 14, y: 5)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { appeared = true }
            }
            if sortedPeople.isEmpty {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    addPulse = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPersonView().environment(\.modelContext, context)
        }
        .sheet(item: $editTarget) { person in
            AddPersonView(editingPerson: person).environment(\.modelContext, context)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(32)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("People")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    if !sortedPeople.isEmpty {
                        Text(subtitleText)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.55))
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var subtitleText: String {
        let peopleStr = "\(sortedPeople.count) \(sortedPeople.count == 1 ? "person" : "people")"
        return "\(peopleStr) · \(upcomingThisMonth) upcoming this month"
    }

    // MARK: - List

    private var peopleList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    PeopleSectionHeader(title: section.title)
                    ForEach(Array(section.people.enumerated()), id: \.element.id) { idx, person in
                        PersonCard(
                            person: person,
                            onEdit: { editTarget = person },
                            onDelete: { deletePerson(person) },
                            onGenerateNow: { generateNow(for: person) }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.78).delay(Double(idx) * 0.05),
                            value: appeared
                        )
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 100)   // room for the FAB
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(accent.opacity(0.6))
                .scaleEffect(addPulse ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: addPulse)

            Text("Add the people you love")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 16)

            Text("We'll remind you when their special days are coming up")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.primary.opacity(0.55))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.top, 8)

            // Primary CTA
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showAdd = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Add Someone")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(height: 52)
                .padding(.horizontal, 32)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x9333ea), Color(hex: 0xc084fc)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: accent.opacity(0.40), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 28)

            HStack(spacing: 5) {
                Image(systemName: "lock.fill").font(.system(size: 10))
                Text("Your people stay private on this device 🔒")
                    .font(.system(size: 12, design: .rounded))
            }
            .foregroundStyle(.primary.opacity(0.45))
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
