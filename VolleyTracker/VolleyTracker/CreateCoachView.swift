import SwiftUI
import SwiftData

struct CreateCoachView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    @State private var name: String = ""
    @State private var showValidation = false
    @State private var goToGroups = false
    @FocusState private var nameFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { trimmedName.count >= 2 }

    var body: some View {
        ZStack {
            // Background image (same as WelcomeView)
            Image("volleyball") // Load the background image named "volleyball"
                .resizable() // Make the image resizable
                .scaledToFill() // Scale the image to fill the screen
                .ignoresSafeArea() // Ignore safe area to cover the entire screen
                .blur(radius: 4)

            // 2) Dark overlay за да изпъква текстът
            LinearGradient(
                colors: [
                    .black.opacity(0.55),
                    .black.opacity(0.35),
                    .black.opacity(0.65),
                    .black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                header

                coachCard

                Spacer()
                Spacer()

                NavigationLink("", isActive: $goToGroups) {
                    GroupsView()
                }
                .hidden()
            }
            .padding(.horizontal, 18)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("VolleyTracker")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white) // <-- set the color you want
            }
        }
        .onAppear {
            // приятен UX: курсора директно в полето
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                nameFocused = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create your coach profile")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Enter your name to start adding groups and players.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.90))
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .colorInvert()
        }
        .padding(.top, 12)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Coach details")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("Coach name")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))

                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.white.opacity(0.7))

                    TextField("e.g. Vladimir", text: $name)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit { createCoach() }

                    if !name.isEmpty {
                        Button {
                            name = ""
                            nameFocused = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            showValidation && !isValid
                            ? Color.red.opacity(0.9)
                            : Color.white.opacity(0.18),
                            lineWidth: 1
                        )
                )

                if showValidation && !isValid {
                    Text("Please enter at least 2 characters.")
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.95))
                }
            }

            Button {
                createCoach()
            } label: {
                HStack(spacing: 10) {
                    Text("Create")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.65)

            Text("You can add more coaches later.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func createCoach() {
        showValidation = true
        guard isValid else { return }

        let coach = Coach(name: trimmedName)
        modelContext.insert(coach)

        let s = settings.first ?? AppSettings()
        if settings.isEmpty { modelContext.insert(s) }
        s.activeCoachId = coach.id

        do {
            try modelContext.save()
            goToGroups = true
        } catch {
            print("Save error:", error)
        }
    }
}

#Preview {
    NavigationStack {
        CreateCoachView()
    }
    .modelContainer(for: [Coach.self, AppSettings.self], inMemory: true)
}
