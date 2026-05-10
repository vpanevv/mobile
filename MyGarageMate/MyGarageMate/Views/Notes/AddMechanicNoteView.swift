import SwiftData
import SwiftUI

struct AddMechanicNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car

    @State private var text = ""
    @State private var date = Date.now
    @State private var mileage = 0.0
    @State private var priority: NotePriority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("What should your mechanic know?", text: $text, axis: .vertical)
                        .lineLimit(4...8)
                        .accessibilityLabel("Mechanic note text")
                    Picker("Priority", selection: $priority) {
                        ForEach(NotePriority.allCases) { priority in
                            Label(priority.title, systemImage: priority.symbolName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Note priority")
                }

                Section("Context") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Mileage", value: $mileage, format: .number)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Note mileage")
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityLabel(validationMessage)
                    }
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .accessibilityLabel("Save mechanic note")
                }
            }
            .onAppear {
                mileage = car.currentMileage
            }
        }
    }

    private var canSave: Bool {
        validationMessage == nil
    }

    private var validationMessage: String? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add a note before saving."
        }
        if mileage < 0 {
            return "Mileage cannot be negative."
        }
        return nil
    }

    private func save() {
        guard canSave else { return }
        let note = MechanicNote(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            mileage: mileage > 0 ? mileage : nil,
            priority: priority
        )
        note.car = car
        car.mechanicNotes.append(note)

        do {
            try modelContext.save()
            HapticsManager.success()
            dismiss()
        } catch {
            assertionFailure("Failed to save mechanic note: \(error)")
        }
    }
}
