import SwiftUI

struct HeartParticle: Identifiable {
    let id = UUID()
    var angle: Double   // degrees
    var distance: CGFloat
    var opacity: Double
}

struct HeartBurstView: View {
    @State private var particles: [HeartParticle] = []
    @State private var animating = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: "heart.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: 0xf43f5e).opacity(particle.opacity))
                    .offset(
                        x: animating ? cos(particle.angle * .pi / 180) * particle.distance : 0,
                        y: animating ? sin(particle.angle * .pi / 180) * particle.distance : 0
                    )
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            emit()
        }
    }

    private func emit() {
        let count = 7
        particles = (0..<count).map { i in
            HeartParticle(
                angle: Double(i) * (360.0 / Double(count)),
                distance: CGFloat.random(in: 40...80),
                opacity: 1.0
            )
        }
        withAnimation(.easeOut(duration: 0.6)) {
            animating = true
            for i in particles.indices {
                particles[i].opacity = 0
            }
        }
    }
}
