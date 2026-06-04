import SwiftUI
import UIKit

// MARK: - FavoriteWishCard (tall vertical card with wish preview)

struct FavoriteWishCard: View {
    let wish: FavoriteWish
    let onDelete: () -> Void
    /// Restart the wish flow pre-filled with this wish's settings.
    let onRegenerate: () -> Void

    @EnvironmentObject var store: FavoritesStore
    @State private var showDetail = false
    @State private var offsetX: CGFloat = 0
    @GestureState private var dragX: CGFloat = 0

    private var occasionType: HolidayType? { HolidayType(rawValue: wish.occasion) }
    private var toneType:     WishTone?    { WishTone.allCases.first { $0.label == wish.tone } }

    private let revealWidth: CGFloat = 76

    var body: some View {
        ZStack(alignment: .trailing) {
            // ── Delete action behind the card ────────────────────────────
            deleteBackground

            // ── Card ─────────────────────────────────────────────────────
            cardBody
                .offset(x: min(0, offsetX + dragX))
                .gesture(swipeGesture)
        }
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            FavoriteDetailView(
                wish: wish,
                onDelete: {
                    showDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDelete() }
                },
                onRegenerate: {
                    showDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onRegenerate() }
                }
            )
            .environmentObject(store)
        }
    }

    // MARK: - Card body

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1 — metadata pills
            HStack(spacing: 8) {
                if let occ = occasionType {
                    pill(occ.rawValue, emoji: occ.emoji, color: occ.accentColor)
                }
                if let tone = toneType {
                    pill(tone.label, color: tone.color)
                }
                Spacer(minLength: 0)
                Text(wish.dateAdded, format: .dateTime.day().month())
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.5))
            }

            // Row 2 — wish preview
            Text(wish.text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .italic()
                .foregroundStyle(.primary.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(3)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Row 3 — recipient + chevron
            HStack {
                if let name = wish.recipientName, !name.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10, weight: .medium))
                        Text("For \(name)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.primary.opacity(0.6))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Capsule())
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.4))
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            if offsetX != 0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { offsetX = 0 }
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showDetail = true
            }
        }
    }

    // MARK: - Delete background (revealed on swipe)

    private var deleteBackground: some View {
        Button {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            onDelete()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Delete")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(width: revealWidth)
            .frame(maxHeight: .infinity)
            .background(Color.red.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .opacity(min(1, Double(abs(min(0, offsetX + dragX)) / revealWidth)))
    }

    // MARK: - Swipe gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .updating($dragX) { value, state, _ in
                // only treat as swipe when horizontal movement dominates
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                state = value.translation.width
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let total = offsetX + value.translation.width
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if value.translation.width < -200 {
                        onDelete()
                        offsetX = 0
                    } else if total < -(revealWidth * 0.55) {
                        offsetX = -revealWidth
                    } else {
                        offsetX = 0
                    }
                }
            }
    }

    // MARK: - Pill

    private func pill(_ text: String, emoji: String? = nil, color: Color) -> some View {
        HStack(spacing: 4) {
            if let emoji { Text(emoji).font(.system(size: 11)) }
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.16))
        .clipShape(Capsule())
    }
}
