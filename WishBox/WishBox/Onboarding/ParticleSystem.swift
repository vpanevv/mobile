import SwiftUI

// MARK: - Particle model

private struct Particle: Identifiable {
    let id: Int
    let isStar: Bool          // true = 4-pointed star, false = circle
    let x: CGFloat            // 0…1 normalized
    let baseY: CGFloat        // 0…1 normalized starting Y
    let size: CGFloat
    let driftSpeed: CGFloat   // pts/s downward drift
    let swayAmp: CGFloat      // horizontal sway amplitude (pts)
    let swayFreq: CGFloat     // sway frequency (cycles/s)
    let phaseOffset: CGFloat  // sway phase offset
    let opacityMin: CGFloat
    let opacityMax: CGFloat
    let opacityFreq: CGFloat  // opacity pulse frequency
    let colorIndex: Int       // 0 = violet, 1 = pink, 2 = white
}

private let palette: [Color] = [
    Color(hex: 0xc084fc),
    Color(hex: 0xf9a8d4),
    Color(hex: 0xffffff),
]

private func makeParticles(count: Int) -> [Particle] {
    var rng = SystemRandomNumberGenerator()
    return (0..<count).map { i in
        Particle(
            id: i,
            isStar: Bool.random(using: &rng),
            x: CGFloat.random(in: 0...1, using: &rng),
            baseY: CGFloat.random(in: 0...1, using: &rng),
            size: CGFloat.random(in: 3...7, using: &rng),
            driftSpeed: CGFloat.random(in: 12...28, using: &rng),
            swayAmp: CGFloat.random(in: 8...22, using: &rng),
            swayFreq: CGFloat.random(in: 0.15...0.45, using: &rng),
            phaseOffset: CGFloat.random(in: 0...(.pi * 2), using: &rng),
            opacityMin: CGFloat.random(in: 0.10...0.30, using: &rng),
            opacityMax: CGFloat.random(in: 0.55...0.90, using: &rng),
            opacityFreq: CGFloat.random(in: 0.20...0.60, using: &rng),
            colorIndex: Int.random(in: 0...2, using: &rng)
        )
    }
}

// MARK: - 4-pointed star path

private func starPath(center: CGPoint, radius: CGFloat) -> Path {
    var path = Path()
    let inner = radius * 0.38
    let points = 4
    for i in 0..<points {
        let outerAngle = (Double(i) * .pi / 2) - .pi / 2
        let innerAngle = outerAngle + .pi / 4
        let op = CGPoint(
            x: center.x + cos(outerAngle) * radius,
            y: center.y + sin(outerAngle) * radius
        )
        let ip = CGPoint(
            x: center.x + cos(innerAngle) * inner,
            y: center.y + sin(innerAngle) * inner
        )
        if i == 0 { path.move(to: op) } else { path.addLine(to: op) }
        path.addLine(to: ip)
    }
    path.closeSubpath()
    return path
}

// MARK: - View

struct ParticleSystemView: View {
    private let particles = makeParticles(count: 36)

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { context, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let elapsed = CGFloat(t) + p.phaseOffset * 0.5

                    // Y wraps: particle drifts down, wraps to top
                    let totalTime = size.height / p.driftSpeed
                    let rawY = p.baseY * size.height + (elapsed * p.driftSpeed).truncatingRemainder(dividingBy: size.height + p.size * 2)
                    let y = rawY.truncatingRemainder(dividingBy: size.height + p.size * 2) - p.size

                    // Sinusoidal sway
                    let swayX = p.swayAmp * sin(2 * .pi * p.swayFreq * elapsed + p.phaseOffset)
                    let cx = p.x * size.width + swayX

                    // Opacity pulse
                    let opacityT = (sin(2 * .pi * p.opacityFreq * elapsed + p.phaseOffset) + 1) / 2
                    let opacity = p.opacityMin + opacityT * (p.opacityMax - p.opacityMin)

                    var ctx2 = context
                    ctx2.opacity = opacity

                    let color = palette[p.colorIndex]
                    let center = CGPoint(x: cx, y: y)

                    if p.isStar {
                        let path = starPath(center: center, radius: p.size)
                        ctx2.fill(path, with: .color(color))
                    } else {
                        let rect = CGRect(
                            x: center.x - p.size / 2,
                            y: center.y - p.size / 2,
                            width: p.size, height: p.size
                        )
                        ctx2.fill(Path(ellipseIn: rect), with: .color(color))
                    }
                    _ = totalTime // silence unused warning
                }
            }
        }
        .drawingGroup()
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
