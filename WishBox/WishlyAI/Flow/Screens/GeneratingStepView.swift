import SwiftUI
import UIKit

// MARK: - GeneratingStepView

struct GeneratingStepView: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @Environment(\.dismiss) private var dismiss

    // Cycling subtitles
    private let subtitles = [
        "Picking the perfect words...",
        "Adding a touch of magic ✨",
        "Almost there...",
        "Making it special...",
    ]
    @State private var subtitleIndex = 0
    @State private var subtitleOpacity: Double = 1
    @State private var rotationAngle: Double = 0
    @State private var pulsing = false
    @State private var appeared = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            FlowAmbientLayer()
            ParticleSystemView()

            VStack(spacing: 0) {
            // ── Progress (shimmer on dot 5) ──────────────────────────────
            FlowProgressBar(currentStep: .generating)
                .padding(.top, 16)
                .padding(.bottom, 0)

            Spacer()

            VStack(spacing: 32) {
                // ── Animated orb ─────────────────────────────────────────
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.neonCyan.opacity(pulsing ? 0.22 : 0.10), .clear],
                                center: .center, startRadius: 0, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulsing)

                    // Glass orb
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.neonCyan.opacity(0.5), Color.neonViolet.opacity(0.3)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: 100, height: 100)

                    // Rotating sparkles
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: i == 0 ? 22 : 14, weight: .semibold))
                            .foregroundStyle(
                                i == 0
                                    ? LinearGradient(colors: [Color.neonCyan, Color.neonViolet], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [Color.neonViolet.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            )
                            .offset(y: i == 0 ? -28 : (i == 1 ? 24 : 0))
                            .offset(x: i == 2 ? 28 : 0)
                            .rotationEffect(.degrees(rotationAngle + Double(i * 120)))
                    }
                }

                // ── Text ─────────────────────────────────────────────────
                VStack(spacing: 12) {
                    Text("Crafting your wish...")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(subtitles[subtitleIndex])
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                        .animation(.easeInOut(duration: 0.35), value: subtitleOpacity)
                }

                // ── Error state ───────────────────────────────────────────
                if let error = errorMessage {
                    VStack(spacing: 16) {
                        Text(error)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        HStack(spacing: 16) {
                            Button {
                                errorMessage = nil
                                // Dismiss back to Length
                                dismiss()
                            } label: {
                                Text("Go back")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            Button {
                                errorMessage = nil
                            } label: {
                                Text("Try again")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.neonCyan)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.neonCyan.opacity(0.12))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.neonCyan.opacity(0.35), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()
            } // end VStack
        } // end ZStack
        .background(Color.clear)
        // Hide nav bar entirely during generation — no back affordance while generating
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation { appeared = true }
            startAnimations()
        }
        .task {
            guard errorMessage == nil else { return }
            await runGeneration()
        }
        .onChange(of: errorMessage) { _, err in
            if err == nil {
                // Retry
                Task { await runGeneration() }
            }
        }
    }

    // MARK: - Generation

    private func runGeneration() async {
        let start = Date()
        do {
            let wish = try await coordinator.generate()

            // Minimum visible time: 1.5s
            let elapsed = Date().timeIntervalSince(start)
            if elapsed < 1.5 {
                try? await Task.sleep(nanoseconds: UInt64((1.5 - elapsed) * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }
            coordinator.generatedWish = wish
            coordinator.isGenerating  = false

            // Navigate: pop self, push result
            coordinator.path.removeLast()
            coordinator.goNext(.result)
        } catch is CancellationError {
            coordinator.isGenerating = false
        } catch {
            coordinator.isGenerating = false
            withAnimation { errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Rotation
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        // Pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pulsing = true
        }
        // Cycling subtitle
        cycleSubtitle()
    }

    private func cycleSubtitle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { subtitleOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                subtitleIndex = (subtitleIndex + 1) % subtitles.count
                withAnimation { subtitleOpacity = 1 }
                cycleSubtitle()
            }
        }
    }
}
