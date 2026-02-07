import SwiftUI
import SwiftData

struct CoachSetupView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var coachName = ""
    @State private var clubName = ""

    private var canCreate: Bool {
        !coachName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clubName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Image("volleyball")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 20)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.blue.opacity(0.25),
                    Color.purple.opacity(0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer(minLength: 70)

                VStack(spacing: 6) {
                    Text("Coach Setup")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Enter your details to create your team space.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 18, y: 10)

                Spacer().frame(height: 28)

                VStack(spacing: 16) {
                    textField("Coach name", text: $coachName)
                    textField("Club", text: $clubName)

                    Button {
                        createCoach()
                    } label: {
                        Text("Create")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: canCreate
                                        ? [Color.orange, Color.orange.opacity(0.8)]
                                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                    }
                    .disabled(!canCreate)
                    .shadow(color: canCreate ? Color.orange.opacity(0.35) : .clear, radius: 12, y: 8)
                }
                .padding(24)
                .frame(maxWidth: 420)
                .background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 25, y: 15)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createCoach() {
        guard canCreate else { return }

        let coach = Coach(
            name: coachName.trimmingCharacters(in: .whitespacesAndNewlines),
            club: clubName.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        modelContext.insert(coach)
        // RootView ще “усети” новия coach и ще смени екрана към Dashboard автоматично.
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18)))
            .foregroundStyle(.white)
            .tint(.white)
    }
}
