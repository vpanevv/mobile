import SwiftUI
import UIKit

struct NeonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                Capsule()
                    .fill(
                        configuration.isOn
                            ? Color.neonCyan.opacity(0.20)
                            : Color.white.opacity(0.06)
                    )
                    .frame(width: 50, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(
                                configuration.isOn
                                    ? Color.neonCyan.opacity(0.55)
                                    : Color.white.opacity(0.10),
                                lineWidth: 1
                            )
                    )

                Circle()
                    .fill(configuration.isOn ? Color.neonCyan : Color.white.opacity(0.35))
                    .frame(width: 22, height: 22)
                    .shadow(color: configuration.isOn ? Color.neonCyan.opacity(0.5) : .clear, radius: 6)
                    .offset(x: configuration.isOn ? 11 : -11)
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: configuration.isOn)
            }
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

struct NameToggleField: View {
    @Binding var includeName: Bool
    @Binding var name: String

    var body: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $includeName) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.neonCyan.opacity(0.8))
                    Text("Include a name")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .toggleStyle(NeonToggleStyle())

            if includeName {
                HStack {
                    TextField("Enter name...", text: $name)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(Color.neonCyan)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.neonCyan.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.neonCyan.opacity(0.28), lineWidth: 1)
                )
                .transition(
                    .opacity
                        .combined(with: .move(edge: .top))
                        .combined(with: .scale(scale: 0.96))
                )
            }
        }
        .padding(18)
        .glassCard()
    }
}
