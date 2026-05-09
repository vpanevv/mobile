import SwiftUI

// MARK: - Individual blob

private struct Blob: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let duration: Double
    let offsetX: CGFloat
    let baseOffsetY: CGFloat
    let parallaxX: Double
    let parallaxY: Double

    @State private var driftY: CGFloat = 0
    @State private var driftX: CGFloat = 0

    var body: some View {
        Ellipse()
            .fill(color.opacity(0.55))
            .frame(width: width, height: height)
            .blur(radius: 80)
            .offset(
                x: offsetX + driftX + CGFloat(parallaxX * 18),
                y: baseOffsetY + driftY + CGFloat(parallaxY * 14)
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    driftY = 30
                    driftX = 18
                }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Ambient blob layer

struct AmbientBlobView: View {
    @ObservedObject var motion: MotionManager

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Blob(
                    color: Color(hex: 0x6b21a8),
                    width: 280, height: 180,
                    duration: 8,
                    offsetX: w * 0.15,
                    baseOffsetY: h * 0.18,
                    parallaxX: -motion.roll,
                    parallaxY: motion.pitch
                )

                Blob(
                    color: Color(hex: 0xbe185d),
                    width: 260, height: 180,
                    duration: 11,
                    offsetX: -w * 0.20,
                    baseOffsetY: h * 0.50,
                    parallaxX: motion.roll,
                    parallaxY: -motion.pitch
                )

                Blob(
                    color: Color(hex: 0x4c1d95),
                    width: 280, height: 170,
                    duration: 7,
                    offsetX: w * 0.10,
                    baseOffsetY: h * 0.72,
                    parallaxX: -motion.roll * 0.7,
                    parallaxY: motion.pitch * 0.7
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
