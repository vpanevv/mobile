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
                    Picker("Priority", selection: $priority) {
                        ForEach(NotePriority.allCases) { priority in
                            Label(priority.title, systemImage: priority.symbolName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Context") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Mileage", value: $mileage, format: .number)
                        .keyboardType(.decimalPad)
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
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                mileage = car.currentMileage
            }
        }
    }

    private func save() {
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
