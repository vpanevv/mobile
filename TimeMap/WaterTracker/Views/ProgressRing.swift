import SwiftUI

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 18)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.18, green: 0.84, blue: 0.96),
                            Color(red: 0.17, green: 0.53, blue: 0.98),
                            Color(red: 0.24, green: 0.91, blue: 0.75)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Daily goal")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(width: 150, height: 150)
    }
}
