import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var appearanceStore: AppearanceStore
    @State private var name = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    Label("ToDoAI", systemImage: "sparkles.rectangle.stack.fill")
                        .font(.title.weight(.bold))
                        .foregroundStyle(primaryTextColor)

                    Text("Start with your name and the app will shape the day around you.")
                        .font(.body)
                        .foregroundStyle(secondaryTextColor)

                    TextField("Your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(fieldBackgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundStyle(primaryTextColor)

                    Button(action: saveProfile) {
                        Text("Enter ToDoAI")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(buttonTextColor)
                    .background(buttonBackgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .disabled(trimmedName.isEmpty)
                    .opacity(trimmedName.isEmpty ? 0.45 : 1)
                }
            }

            Text("Simple daily planning, clear focus, and AI-assisted suggestions.")
                .font(.footnote)
                .foregroundStyle(secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
        .padding(24)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var primaryTextColor: Color {
        appearanceStore.appearance.isDark ? .white : Color.black.opacity(0.86)
    }

    private var secondaryTextColor: Color {
        appearanceStore.appearance.isDark ? .white.opacity(0.72) : Color.black.opacity(0.62)
    }

    private var fieldBackgroundColor: Color {
        appearanceStore.appearance.isDark ? Color.white.opacity(0.14) : Color.white.opacity(0.82)
    }

    private var buttonBackgroundColor: Color {
        appearanceStore.appearance.isDark ? Color.white : Color.black.opacity(0.88)
    }

    private var buttonTextColor: Color {
        appearanceStore.appearance.isDark ? .black : .white
    }

    private func saveProfile() {
        guard !trimmedName.isEmpty else { return }
        store.saveProfile(name: trimmedName)
    }
}
