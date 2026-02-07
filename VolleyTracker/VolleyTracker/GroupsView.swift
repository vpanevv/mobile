//
//  GroupsView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 07/02/2026.
//

import SwiftUI
import SwiftData

struct GroupsView: View {
    let coach: Coach

    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [Group]

    @State private var showCreateGroup = false
    @State private var editingGroup: Group?
    @State private var deletingGroup: Group?
    @State private var showDeleteConfirm = false

    init(coach: Coach) {
        self.coach = coach

        let coachID = coach.persistentModelID

        _groups = Query(
            filter: #Predicate<Group> { group in
                group.coach?.persistentModelID == coachID
            },
            sort: [SortDescriptor(\Group.createdAt, order: .reverse)]
        )
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            Image("volleyball")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 5)

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                // Top date
                Text(dateText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 12)

                // Title
                Text("Groups")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                // List / Empty state
                if groups.isEmpty {
                    VStack(spacing: 10) {
                        Text("No groups yet")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Create your first group to start tracking attendance.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Button {
                            showCreateGroup = true
                        } label: {
                            Text("Create Group")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                )
                        }
                        .shadow(color: Color.orange.opacity(0.35), radius: 12, y: 8)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .padding(.top, 22)

                    Spacer()
                } else {
                    List {
                        ForEach(groups) { group in
                            GroupRowView(group: group)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                                    Button(role: .destructive) {
                                        deletingGroup = group
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        editingGroup = group
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateGroup = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .accessibilityLabel("Create Group")
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupSheet(coach: coach) { newGroupName in
                createGroup(named: newGroupName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        
        .sheet(item: $editingGroup) { group in
            EditGroupSheet(group: group) { newName in
                rename(group, to: newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        
        .confirmationDialog(
            deletingGroup != nil
                ? "Delete \"\(deletingGroup!.name)\"?"
                : "Delete group?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let group = deletingGroup {
                    delete(group)
                }
                deletingGroup = nil
            }

            Button("Cancel", role: .cancel) {
                deletingGroup = nil
            }
        } message: {
            if let group = deletingGroup {
                Text("This will delete \"\(group.name)\" and all its players.")
            }
        }
    }

    private func createGroup(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newGroup = Group(name: trimmed, coach: coach)
        modelContext.insert(newGroup)
        try? modelContext.save()   // за “сигурно” при onboarding / create

        // Нищо друго не правим — @Query ще refresh-не и групата ще се появи автоматично
    }
    private func delete(_ group: Group) {
        modelContext.delete(group)
        try? modelContext.save()
    }

    private func rename(_ group: Group, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        group.name = trimmed
        try? modelContext.save()
    }

}

private struct GroupRowView: View {
    let group: Group

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.25))
                    .frame(width: 36, height: 36)

                Image(systemName: "person.3.fill")
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Players: \(group.players.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
