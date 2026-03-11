import SwiftUI

struct CompletedTasksView: View {
    @EnvironmentObject private var store: AppStore

    let tasks: [TodoTask]
    let onBack: () -> Void

    @State private var showingDeleteAllConfirmation = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Completed Tasks")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)

                            Text(tasks.isEmpty ? "No completed tasks yet." : "A full record of every task you finished.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.74))

                            if tasks.isEmpty {
                                Text("Finish a task from the dashboard and it will show up here.")
                                    .foregroundStyle(.white.opacity(0.68))
                                    .padding(.top, 4)
                            } else {
                                ForEach(tasks) { task in
                                    completedTaskRow(task)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
        }
        .confirmationDialog(
            "Delete completed tasks?",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                store.deleteCompletedTasks()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all completed tasks from your lists.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.black))

                    Text("Back")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.10), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    showingDeleteAllConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.caption.weight(.black))

                        Text("Clear Completed")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.88), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(tasks.isEmpty)
                .opacity(tasks.isEmpty ? 0.45 : 1)

                Text("\(tasks.count) done")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.10), in: Capsule())
            }
        }
    }

    private func completedTaskRow(_ task: TodoTask) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: "checkmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)

                Text(completedTaskSubtitle(for: task))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            PriorityBadge(priority: task.priority)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func completedTaskSubtitle(for task: TodoTask) -> String {
        let completedText = task.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
        return "Completed \(completedText)"
    }
}
