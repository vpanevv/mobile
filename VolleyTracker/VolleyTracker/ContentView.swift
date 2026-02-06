import SwiftUI

struct ContentView: View {
    @State private var goToSetup = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image
                Image("volleyball")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 5)

                // Dark overlay
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 80)

                    // Glass Card for Title
                    VStack(spacing: 8) {
                        Text("Volley Tracker")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Track attendance. Stay organized")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)

                    Spacer()

                    Button {
                        goToSetup = true
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.orange))
                    }
                    .shadow(color: Color.orange.opacity(0.35), radius: 14, y: 8)

                    Spacer(minLength: 120)

                    Text("Designed for coaches • v1.0")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding()
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $goToSetup) {
                CoachSetupView()
                    .navigationBarBackButtonHidden(false)
            }
        }
    }
}

#Preview {
    ContentView()
}
