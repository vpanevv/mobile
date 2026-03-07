import SwiftUI

struct TaskComposerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedPriority: TaskPriority = .important

    let onCreate: (String, TaskPriority) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                LiveClockHeader()

                Spacer(minLength: 0)

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Create a task for today")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)

                        TextField("Task title", text: $title, axis: .vertical)
                            .textInputAutocapitalization(.sentences)
                            .lineLimit(2...4)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority")
                                .font(.headline)

                            VStack(spacing: 12) {
                                ForEach(TaskPriority.allCases) { priority in
                                    Button {
                                        selectedPriority = priority
                                    } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: priority.symbolName)
                                                .font(.headline)
                                                .frame(width: 28)

                                            Text(priority.title)
                                                .font(.headline.weight(.semibold))

                                            Spacer()

                                            if selectedPriority == priority {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.title3)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(selectedPriority == priority ? .black : .white)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(selectedPriority == priority ? Color.white : priority.tint.opacity(0.28))
                                        )
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(
                                                    selectedPriority == priority ? Color.white : priority.tint.opacity(0.9),
                                                    lineWidth: 1.2
                                                )
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Button(action: createTask) {
                    Text("Create Task")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .disabled(trimmedTitle.isEmpty)
                .opacity(trimmedTitle.isEmpty ? 0.5 : 1)

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(AppBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createTask() {
        guard !trimmedTitle.isEmpty else { return }
        onCreate(trimmedTitle, selectedPriority)
        dismiss()
    }
}
