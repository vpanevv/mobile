//
//  HelloCoachView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 01/02/2026.
//

import SwiftUI
import SwiftData

struct HelloCoachView: View {
    @Environment(\.modelContext) private var modelContext

    // settings държи activeCoachId
    @Query private var settings: [AppSettings]

    @State private var activeCoach: Coach?
    @State private var groups: [Group] = []

    // UI state
    @State private var showCreateGroupSheet = false
    @State private var editingGroup: Group? = nil
    @State private var pendingDelete: Group? = nil

    var body: some View {
        ZStack {
            // same background style
            Image("volleyball")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial)

            VStack(spacing: 14) {
                headerCard

                groupsCard

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadActiveCoachAndGroups()
        }
        .sheet(isPresented: $showCreateGroupSheet) {
            GroupEditorSheet(
                title: "New group",
                initialName: "",
                confirmTitle: "Create",
                onConfirm: { name in
                    createGroup(name: name)
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $editingGroup) { g in
            GroupEditorSheet(
                title: "Edit group",
                initialName: g.name,
                confirmTitle: "Save",
                onConfirm: { newName in
                    renameGroup(g, to: newName)
                }
            )
            .presentationDetents([.medium])
        }
        // iOS-style confirm (като action sheet / confirmation dialog)
        .confirmationDialog(
            "Delete group?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let g = pendingDelete { deleteGroup(g) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This will delete the group. (Players & trainings will be added later.)")
        }
    }

    // MARK: - UI Parts

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hello\(activeCoachNamePrefix)")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(formattedDate())
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))

            Text("Ready for today’s trainings?")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var groupsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your groups")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    showCreateGroupSheet = true
                } label: {
                    Label("Add group", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            if groups.isEmpty {
                Text("No groups yet. Tap “Add group” to create your first one.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 6)
            } else {
                VStack(spacing: 10) {
                    ForEach(groups) { g in
                        groupRow(g)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func groupRow(_ g: Group) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .foregroundStyle(.white.opacity(0.85))

            VStack(alignment: .leading, spacing: 2) {
                Text(g.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Tap to open (players next)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Menu {
                Button("Edit") { editingGroup = g }
                Button("Delete", role: .destructive) { pendingDelete = g }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // TODO: утре/след това -> навигация към PlayersView(groupId: g.id)
            print("Open group:", g.name)
        }
    }

    private var activeCoachNamePrefix: String {
        guard let n = activeCoach?.name, !n.isEmpty else { return "" }
        return ", coach \(n)"
    }

    // MARK: - Data

    private func loadActiveCoachAndGroups() {
        let activeId = settings.first?.activeCoachId  // UUID?

        if let id = activeId, let coach = fetchCoach(id: id) {
            activeCoach = coach
            groups = fetchGroups(for: coach)
        } else {
            activeCoach = nil
            groups = []
        }
    }

    private func fetchCoach(id: UUID) -> Coach? {
        let d = FetchDescriptor<Coach>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(d))?.first
    }

    private func fetchGroups(for coach: Coach) -> [Group] {
        let coachId = coach.id   // ✅ константа (UUID), това SwiftData го харесва

        let d = FetchDescriptor<Group>(
            predicate: #Predicate { $0.coachId == coachId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return (try? modelContext.fetch(d)) ?? []
    }

    private func createGroup(name: String) {
        guard let coach = activeCoach else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }

        let exists = groups.contains { $0.name.lowercased() == trimmed.lowercased() }
        guard !exists else { return }

        let g = Group(name: trimmed, coachId: coach.id, coach: coach)
        modelContext.insert(g)

        do {
            try modelContext.save()
            loadActiveCoachAndGroups()
        } catch {
            print("Create group save error:", error)
        }
    }

    private func renameGroup(_ g: Group, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }

        let exists = groups.contains { $0.id != g.id && $0.name.lowercased() == trimmed.lowercased() }
        guard !exists else { return }

        g.name = trimmed

        do {
            try modelContext.save()
            loadActiveCoachAndGroups()
        } catch {
            print("Rename group save error:", error)
        }
    }

    private func deleteGroup(_ g: Group) {
        modelContext.delete(g)

        do {
            try modelContext.save()
            loadActiveCoachAndGroups()
        } catch {
            print("Delete group save error:", error)
        }
    }

    private func formattedDate() -> String {
        let df = DateFormatter()
        df.dateStyle = .full
        return df.string(from: .now)
    }
}
