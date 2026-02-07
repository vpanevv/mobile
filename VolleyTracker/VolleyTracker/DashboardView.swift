import SwiftUI
import SwiftData

struct DashboardView: View {
    let coach: Coach

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .full   // Saturday, February 7, 2026 (ще е на езика на устройството)
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("volleyball")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 5)

                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: 18) {

                    // Top date
                    Text(dateText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.top, 18)

                    Spacer()

                    // Center content
                    VStack(spacing: 10) {
                        Text("Welcome coach \(coach.name)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Ready for today's practice?")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 18, y: 10)

                    // Groups button
                    NavigationLink {
                        GroupsView(coach: coach)
                    } label: {
                        Text("Groups")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                    }
                    .shadow(color: Color.orange.opacity(0.35), radius: 12, y: 8)
                    .padding(.top, 6)

                    Spacer()
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
