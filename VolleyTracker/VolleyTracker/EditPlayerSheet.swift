//
//  EditPlayerSheet.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 07/02/2026.
//

import SwiftUI

struct EditPlayerSheet: View {
    let player: Player
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(player: Player, onSave: @escaping (String) -> Void) {
        self.player = player
        self.onSave = onSave
        _name = State(initialValue: player.name)
    }

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != player.name
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color.blue.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Edit Player")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                TextField("Player name", text: $name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18)))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .autocorrectionDisabled()

                HStack(spacing: 12) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.white.opacity(0.10)))

                    Button {
                        guard canSave else { return }
                        onSave(name)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: canSave
                                        ? [Color.orange, Color.orange.opacity(0.8)]
                                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                    }
                    .disabled(!canSave)
                }

                Spacer()
            }
            .padding(22)
        }
    }
}
