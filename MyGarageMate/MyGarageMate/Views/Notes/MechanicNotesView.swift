import SwiftData
import SwiftUI

struct MechanicNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car
    @State private var notePendingDeletion: MechanicNote?
    @State private var notePendingEdit: MechanicNote?

    var body: some View {
        Group {
            if car.notesNewestFirst.isEmpty {
                EmptyStateView(
                    symbolName: "note.text",
                    title: "No mechanic notes",
                    message: "Keep quick observations here so small symptoms are not forgotten."
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(car.notesNewestFirst, id: \.id) { note in
                        noteRow(note)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    notePendingEdit = note
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)

                                Button(role: .destructive) {
                                    notePendingDeletion = note
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    notePendingEdit = note
                                } label: {
                                    Label("Edit Note", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    notePendingDeletion = note
                                } label: {
                                    Label("Delete Note", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { notePendingEdit != nil },
                set: { if !$0 { notePendingEdit = nil } }
            )
        ) {
            if let notePendingEdit {
                EditMechanicNoteView(note: notePendingEdit, car: car)
            }
        }
        .confirmationDialog(
            "Delete mechanic note?",
            isPresented: Binding(
                get: { notePendingDeletion != nil },
                set: { if !$0 { notePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Note", role: .destructive) {
                deletePendingNote()
            }
            Button("Cancel", role: .cancel) {
                notePendingDeletion = nil
            }
        } message: {
            Text("This removes the selected mechanic note from this device.")
        }
    }

    private func deletePendingNote() {
        guard let note = notePendingDeletion else { return }
        modelContext.delete(note)
        do {
            try modelContext.save()
            HapticsManager.warning()
        } catch {
            assertionFailure("Failed to delete mechanic note: \(error)")
        }
        notePendingDeletion = nil
    }

    private func noteRow(_ note: MechanicNote) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Image(systemName: note.priority.symbolName)
                    .foregroundStyle(priorityColor(note.priority))
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button {
                        notePendingEdit = note
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                            .frame(width: 30, height: 30)
                            .background(.blue.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit note")

                    Button(role: .destructive) {
                        notePendingDeletion = note
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.red)
                            .frame(width: 30, height: 30)
                            .background(.red.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete note")

                    Text(note.priority.title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(priorityColor(note.priority).opacity(0.14), in: Capsule())
                        .foregroundStyle(priorityColor(note.priority))
                }

                Text(note.text)
                    .font(.body)

                if let mileage = note.mileage {
                    Label("\(mileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)", systemImage: "gauge.with.dots.needle.67percent")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func priorityColor(_ priority: NotePriority) -> Color {
        switch priority {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}

private struct EditMechanicNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let note: MechanicNote
    let car: Car

    @State private var text: String
    @State private var date: Date
    @State private var mileage: Double
    @State private var priority: NotePriority

    init(note: MechanicNote, car: Car) {
        self.note = note
        self.car = car
        _text = State(initialValue: note.text)
        _date = State(initialValue: note.date)
        _mileage = State(initialValue: note.mileage ?? car.currentMileage)
        _priority = State(initialValue: note.priority)
    }

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
                    }
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(validationMessage != nil)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var validationMessage: String? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add note text before saving."
        }
        if mileage < 0 {
            return "Mileage cannot be negative."
        }
        return nil
    }

    private func save() {
        guard validationMessage == nil else { return }
        note.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        note.date = date
        note.mileage = mileage > 0 ? mileage : nil
        note.priority = priority

        do {
            try modelContext.save()
            HapticsManager.success()
            dismiss()
        } catch {
            assertionFailure("Failed to edit mechanic note: \(error)")
        }
    }
}
