import SwiftUI

struct TaskComposerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedPriority: TaskPriority = .important

    let onCreate: (String, TaskPriority) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                sheetHeader

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Create a task for today")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.86))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)

                    TextField("Task title", text: $title, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(2...4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        }
                        .foregroundStyle(Color.black.opacity(0.84))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority")
                            .font(.headline)
                            .foregroundStyle(Color.black.opacity(0.78))

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
                                    .foregroundStyle(Color.black.opacity(0.84))
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(selectedPriority == priority ? Color.white : priority.tint.opacity(0.16))
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(
                                                selectedPriority == priority ? Color.black.opacity(0.08) : priority.tint.opacity(0.34),
                                                lineWidth: 1.2
                                            )
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(22)
                .background(sheetCardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                }
                .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)

                Button(action: createTask) {
                    Text("Create Task")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.86, green: 0.97, blue: 0.99),
                            Color(red: 0.77, green: 0.93, blue: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                }
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

    private var sheetHeader: some View {
        VStack(spacing: 10) {
            Label("Task Composer", systemImage: "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.84))

            LiveClockHeader(style: .contrastOnLight)
        }
        .padding(22)
        .background(sheetCardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
        }
        .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)
    }

    private var sheetCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 1.0, blue: 1.0),
                            Color(red: 0.89, green: 0.97, blue: 0.99),
                            Color(red: 0.97, green: 0.98, blue: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .offset(x: -120, y: -90)

            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 22)
                .offset(x: 110, y: 80)
        }
    }

    private func createTask() {
        guard !trimmedTitle.isEmpty else { return }
        onCreate(trimmedTitle, selectedPriority)
        dismiss()
    }
}
