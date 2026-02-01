//
//  GroupEditorSheet.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 01/02/2026.
//

import SwiftUI

struct GroupEditorSheet: View {
    let title: String
    let initialName: String
    let confirmTitle: String
    let onConfirm: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var showValidation = false

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { trimmed.count >= 2 }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Group name")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("e.g. U12 / Beginners", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(showValidation && !isValid ? Color.red.opacity(0.85) : Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                if showValidation && !isValid {
                    Text("Please enter at least 2 characters.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(confirmTitle) {
                        showValidation = true
                        guard isValid else { return }
                        onConfirm(trimmed)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            self.name = initialName
        }
    }
}
