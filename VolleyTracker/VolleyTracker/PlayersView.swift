//
//  PlayersView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 07/02/2026.
//

import SwiftUI
import SwiftData

struct PlayersView: View {
    let group: Group

    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]

    @State private var showAddPlayer = false
    @State private var editingPlayer: Player?

    @State private var deletingPlayer: Player?
    @State private var showDeleteConfirm = false

    init(group: Group) {
        self.group = group

        let groupID = group.persistentModelID

        _players = Query(
            filter: #Predicate<Player> { player in
                player.group?.persistentModelID == groupID
            },
            sort: [SortDescriptor(\Player.createdAt, order: .reverse)]
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

            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(dateText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 12)

                Text(group.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if players.isEmpty {
                    emptyState
                    Spacer()
                } else {
                    List {
                        ForEach(players) { player in
                            PlayerRowView(player: player)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                                    Button(role: .destructive) {
                                        deletingPlayer = player
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        editingPlayer = player
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
                    showAddPlayer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .accessibilityLabel("Add Player")
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerSheet(group: group) { name in
                addPlayer(named: name)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingPlayer) { player in
            EditPlayerSheet(player: player) { newName in
                rename(player, to: newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            deletingPlayer != nil ? "Delete \"\(deletingPlayer!.name)\"?" : "Delete player?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let p = deletingPlayer { delete(p) }
                deletingPlayer = nil
            }
            Button("Cancel", role: .cancel) {
                deletingPlayer = nil
            }
        } message: {
            if let p = deletingPlayer {
                Text("This will delete \"\(p.name)\" from \(group.name).")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No players yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("Add players to start taking attendance.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                showAddPlayer = true
            } label: {
                Text("Add Player")
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
    }

    private func addPlayer(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let player = Player(name: trimmed, group: group)
        modelContext.insert(player)
        try? modelContext.save()
    }

    private func rename(_ player: Player, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        player.name = trimmed
        try? modelContext.save()
    }

    private func delete(_ player: Player) {
        modelContext.delete(player)
        try? modelContext.save()
    }
}

private struct PlayerRowView: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.25))
                    .frame(width: 36, height: 36)

                Image(systemName: "person.fill")
                    .foregroundStyle(.orange)
            }

            Text(player.name)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.35))
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
