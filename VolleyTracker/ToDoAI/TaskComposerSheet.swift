import SwiftUI

struct TaskComposerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedPriority: TaskPriority = .important

    let onCreate: (String, TaskPriority) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Create a task for today")
                            .font(.title3.weight(.bold))

                        TextField("Task title", text: $title, axis: .vertical)
                            .textInputAutocapitalization(.sentences)
                            .lineLimit(2...4)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority")
                                .font(.headline)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                                ForEach(TaskPriority.allCases) { priority in
                                    Button {
                                        selectedPriority = priority
                                    } label: {
                                        HStack {
                                            Image(systemName: priority.symbolName)
                                            Text(priority.title)
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .foregroundStyle(selectedPriority == priority ? .black : priority.tint)
                                        .background(
                                            (selectedPriority == priority ? Color.white : priority.tint.opacity(0.12)),
                                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Button(action: createTask) {
                    Text("Save Task")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .disabled(trimmedTitle.isEmpty)
                .opacity(trimmedTitle.isEmpty ? 0.5 : 1)

                Spacer()
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
