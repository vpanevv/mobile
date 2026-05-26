import SwiftUI
import UIKit

// MARK: - Liquid-glass snapping tone slider

struct ToneSlider: View {
    @Binding var selectedTone: WishTone

    @AppStorage("lastToneRaw") private var lastToneRaw: Int = WishTone.friendly.rawValue

    @State private var thumbX: CGFloat = 0
    @State private var isDragging = false
    @State private var lastStepIndex: Int = -1
    @State private var trackWidth: CGFloat = 0

    private let thumbSize: CGFloat = 40
    private let trackHeight: CGFloat = 8
    private let tones = WishTone.allCases

    // Position (0…trackWidth) for a given tone
    private func stepX(for tone: WishTone, in w: CGFloat) -> CGFloat {
        guard w > 0 else { return 0 }
        return CGFloat(tone.rawValue) / CGFloat(tones.count - 1) * w
    }

    // Nearest tone for a drag position
    private func nearestTone(x: CGFloat, in w: CGFloat) -> WishTone {
        guard w > 0 else { return .friendly }
        let ratio = (x / w * CGFloat(tones.count - 1)).rounded()
        let idx = max(0, min(Int(ratio), tones.count - 1))
        return WishTone(rawValue: idx) ?? .friendly
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ───────────────────────────────────────────────────
            HStack(spacing: 10) {
                Text("TONE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)

                // Animated tone pill
                HStack(spacing: 5) {
                    Text(selectedTone.emoji)
                        .font(.system(size: 13))
                        .contentTransition(.symbolEffect(.replace))
                    Text(selectedTone.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(selectedTone.color)
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedTone)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedTone.color.opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selectedTone.color.opacity(0.35), lineWidth: 0.8)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedTone)
            }

            // ── Slider ───────────────────────────────────────────────────
            GeometryReader { geo in
                let w = geo.size.width - thumbSize   // usable track width
                ZStack(alignment: .leading) {

                    // Track background
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbSize / 2)

                    // Active fill (left side of thumb)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: tones.map { $0.color },
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .opacity(0.85)
                        )
                        .frame(
                            width: max(0, thumbX + thumbSize / 2),
                            height: trackHeight
                        )
                        .padding(.leading, thumbSize / 2)
                        .clipped()

                    // Tick marks
                    ForEach(tones) { tone in
                        let tx = stepX(for: tone, in: w) + thumbSize / 2
                        let isActive = tone.rawValue <= selectedTone.rawValue
                        Circle()
                            .fill(isActive ? tone.color : Color.primary.opacity(0.18))
                            .frame(
                                width: tone == selectedTone ? 7 : 4,
                                height: tone == selectedTone ? 7 : 4
                            )
                            .shadow(
                                color: tone == selectedTone ? tone.color.opacity(0.6) : .clear,
                                radius: 4
                            )
                            .position(x: tx, y: geo.size.height / 2)
                            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: selectedTone)
                    }

                    // Thumb
                    ZStack {
                        // Outer glass circle
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: thumbSize, height: thumbSize)
                            .shadow(color: selectedTone.color.opacity(isDragging ? 0.45 : 0.25),
                                    radius: isDragging ? 14 : 8)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.55),
                                                selectedTone.color.opacity(0.45)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.2
                                    )
                            )

                        // Colored inner dot
                        Circle()
                            .fill(selectedTone.color)
                            .frame(width: 14, height: 14)
                            .shadow(color: selectedTone.color.opacity(0.7), radius: 4)

                        // Emoji
                        Text(selectedTone.emoji)
                            .font(.system(size: 16))
                            .offset(y: -1)
                    }
                    .scaleEffect(isDragging ? 1.12 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: selectedTone)
                    .position(x: thumbX + thumbSize / 2, y: geo.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { val in
                            isDragging = true
                            let rawX = val.location.x - thumbSize / 2
                            let clampedX = max(0, min(rawX, w))
                            thumbX = clampedX

                            let tone = nearestTone(x: clampedX, in: w)
                            if tone.rawValue != lastStepIndex {
                                lastStepIndex = tone.rawValue
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedTone = tone
                                lastToneRaw = tone.rawValue
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            // Spring-snap to exact step
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                                thumbX = stepX(for: selectedTone, in: w)
                            }
                            lastToneRaw = selectedTone.rawValue
                        }
                )
                .onAppear {
                    trackWidth = w
                    thumbX = stepX(for: selectedTone, in: w)
                    lastStepIndex = selectedTone.rawValue
                }
                .onChange(of: selectedTone) { _, newTone in
                    if !isDragging {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            thumbX = stepX(for: newTone, in: w)
                        }
                    }
                }
                .onChange(of: geo.size.width) { _, _ in
                    let newW = geo.size.width - thumbSize
                    thumbX = stepX(for: selectedTone, in: newW)
                }
            }
            .frame(height: thumbSize)

            // ── End labels ───────────────────────────────────────────────
            HStack {
                Text(tones.first!.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.6))
                Spacer()
                Text(tones.last!.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, thumbSize / 2)
        }
    }
}
