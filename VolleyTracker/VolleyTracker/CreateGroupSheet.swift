//
//  CreateGroupSheet.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 07/02/2026.
//

import SwiftUI

struct CreateGroupSheet: View {
    let coach: Coach
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var groupName: String = ""

    private var canCreate: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color.purple.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Create Group")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Coach: \(coach.name)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))

                TextField("Group name (e.g. U16 Boys)", text: $groupName)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18)))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .autocorrectionDisabled()

                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white.opacity(0.10)))

                    Button {
                        guard canCreate else { return }
                        onCreate(groupName)
                        dismiss()
                    } label: {
                        Text("Create")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: canCreate
                                        ? [Color.orange, Color.orange.opacity(0.8)]
                                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                    }
                    .disabled(!canCreate)
                }
                .padding(.top, 6)

                Spacer()
            }
            .padding(22)
        }
    }
}
