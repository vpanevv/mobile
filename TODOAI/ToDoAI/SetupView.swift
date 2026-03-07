import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var store: AppStore
    @State private var name = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    Label("ToDoAI", systemImage: "sparkles.rectangle.stack.fill")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Start with your name and the app will shape the day around you.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.82))

                    TextField("Your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Button(action: saveProfile) {
                        Text("Enter ToDoAI")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .disabled(trimmedName.isEmpty)
                    .opacity(trimmedName.isEmpty ? 0.45 : 1)
                }
            }

            Text("Simple daily planning, clear focus, and AI-assisted suggestions.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
        .padding(24)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveProfile() {
        guard !trimmedName.isEmpty else { return }
        store.saveProfile(name: trimmedName)
    }
}
