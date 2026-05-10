import SwiftData
import SwiftUI

struct MechanicNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car
    @State private var notePendingDeletion: MechanicNote?

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
                    ForEach(car.notesNewestFirst) { note in
                        noteRow(note)
                            .swipeActions {
                                Button(role: .destructive) {
                                    notePendingDeletion = note
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
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
        .accessibilityElement(children: .combine)
    }

    private func priorityColor(_ priority: NotePriority) -> Color {
        switch priority {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}
