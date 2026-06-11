import SwiftUI
import UIKit

// MARK: - FavoriteDetailView

struct FavoriteDetailView: View {
    let wish: FavoriteWish
    let onDelete: () -> Void
    /// Dismiss everything and restart the wish flow pre-filled with this wish's settings.
    let onRegenerate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = ProStore.shared
    @AppStorage("wishlyai.isDark") private var isDark: Bool = true

    @State private var copied            = false
    @State private var showDeleteConfirm = false
    @State private var showCardEditor    = false
    @State private var showPaywall       = false
    @State private var cardAppeared      = false
    @State private var actionsAppeared   = false

    private var occasionType: HolidayType? { HolidayType(rawValue: wish.occasion) }
    private var toneType:     WishTone?    { WishTone.allCases.first { $0.label == wish.tone } }
    private var lengthType:   WishLength?  { WishLength(rawValue: wish.length) }

    var body: some View {
        ZStack {
            NeuralBackground().ignoresSafeArea()
            FlowAmbientLayer()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Metadata pills
                        HStack(spacing: 8) {
                            if let occ = occasionType {
                                metaPill(occ.rawValue, emoji: occ.emoji, color: occ.accentColor)
                            }
                            if let tone = toneType {
                                metaPill(tone.label, emoji: tone.emoji, color: tone.color)
                            }
                            if let len = lengthType {
                                metaPill(len.rawValue, icon: len.icon, color: len.color)
                            }
                        }
                        .padding(.top, 10)

                        // Hero wish card
                        Text(wish.text)
                            .font(.system(size: 22, weight: .regular, design: .rounded))
                            .italic()
                            .foregroundStyle(.primary.opacity(0.92))
                            .lineSpacing(6)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(28)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.neonCyan.opacity(0.40), Color.neonViolet.opacity(0.25)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.neonCyan.opacity(0.10), radius: 20, y: 4)
                            .scaleEffect(cardAppeared ? 1 : 0.92)
                            .opacity(cardAppeared ? 1 : 0)

                        // Recipient + saved date
                        VStack(spacing: 4) {
                            if let name = wish.recipientName, !name.isEmpty {
                                HStack(spacing: 5) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("For \(name)")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(.primary.opacity(0.6))
                            }
                            Text("Saved \(wish.dateAdded.formatted(.dateTime.day().month()))")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                // Action buttons
                HStack(spacing: 22) {
                    actionCircle(icon: copied ? "checkmark" : "doc.on.doc",
                                 tint: copied ? .green : Color.neonCyan,
                                 isActive: copied) {
                        UIPasteboard.general.string = wish.text
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copied = false }
                        }
                    }
                    actionCircle(icon: "wand.and.stars", tint: Color(hex: 0xc084fc)) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if pro.isPro {
                            showCardEditor = true
                        } else {
                            showPaywall = true
                        }
                    }
                    actionCircle(icon: "arrow.clockwise", tint: Color(hex: 0x22d3ee)) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onRegenerate()
                    }
                }
                .padding(.top, 6)
                .opacity(actionsAppeared ? 1 : 0)
                .offset(y: actionsAppeared ? 0 : 14)

                // Use as template
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onRegenerate()
                } label: {
                    HStack(spacing: 5) {
                        Text("Use as template")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.primary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .opacity(actionsAppeared ? 1 : 0)
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .presentationDetents([.large])
        .presentationCornerRadius(32)
        .presentationDragIndicator(.hidden)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.05)) {
                cardAppeared = true
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.22)) {
                actionsAppeared = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView(context: .cardMode)
        }
        .fullScreenCover(isPresented: $showCardEditor) {
            CardEditorView(
                wishText: wish.text,
                occasion: wish.occasion,
                recipientName: wish.recipientName
            )
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            glassCircleButton(icon: "xmark", tint: .secondary) { dismiss() }

            Spacer()

            Text("Saved Wish")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            glassCircleButton(icon: "trash", tint: Color.red.opacity(0.75)) {
                showDeleteConfirm = true
            }
            .confirmationDialog("Remove from favorites?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Remove", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This wish will be permanently removed.")
            }
        }
    }

    // MARK: - Components

    private func glassCircleButton(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func actionCircle(icon: String, tint: Color, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isActive ? tint : .primary.opacity(0.85))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 64, height: 64)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(isActive ? tint.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1))
                .shadow(color: isActive ? tint.opacity(0.3) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }

    private func metaPill(_ text: String, emoji: String? = nil, icon: String? = nil, color: Color) -> some View {
        HStack(spacing: 5) {
            if let emoji { Text(emoji).font(.system(size: 11)) }
            if let icon  { Image(systemName: icon).font(.system(size: 10, weight: .semibold)).foregroundStyle(color) }
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}
