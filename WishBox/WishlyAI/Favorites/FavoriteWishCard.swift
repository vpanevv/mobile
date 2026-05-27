import SwiftUI
import UIKit

// MARK: - Compact row shown in the list

struct FavoriteWishCard: View {
    let wish: FavoriteWish
    let onDelete: () -> Void

    @EnvironmentObject var store: FavoritesStore
    @State private var showDetail = false
    @State private var showDeleteConfirm = false

    private var occasionType: HolidayType? { HolidayType(rawValue: wish.occasion) }
    private var toneType: WishTone?         { WishTone.allCases.first { $0.label == wish.tone } }

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 10) {
                // Occasion icon badge
                if let occ = occasionType {
                    ZStack {
                        Circle()
                            .fill(Color.neonCyan.opacity(0.14))
                            .frame(width: 38, height: 38)
                        Image(systemName: occ.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.neonCyan)
                    }
                }

                // Middle — pills + name
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let occ = occasionType {
                            pill(occ.rawValue, color: Color.neonCyan)
                        }
                        if let tone = toneType {
                            pill(tone.label, color: tone.color)
                        }
                    }

                    if let name = wish.recipientName, !name.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("For \(name)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer(minLength: 0)

                // Date — right aligned
                Text(wish.dateAdded, format: .dateTime.day().month())
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.55))
                    .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            FavoriteWishDetailView(wish: wish, onDelete: {
                showDetail = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDelete() }
            })
            .environmentObject(store)
        }
    }

    private func pill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

// MARK: - Full detail sheet

struct FavoriteWishDetailView: View {
    let wish: FavoriteWish
    let onDelete: () -> Void

    @EnvironmentObject var store: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var showDeleteConfirm = false
    @State private var showCardEditor = false

    private var occasionType: HolidayType? { HolidayType(rawValue: wish.occasion) }
    private var toneType: WishTone?         { WishTone.allCases.first { $0.label == wish.tone } }
    private var lengthType: WishLength?     { WishLength(rawValue: wish.length) }

    var body: some View {
        ZStack {
            // Subtle background
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.primary.opacity(0.18))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Header — occasion + close
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                if let occ = occasionType {
                                    HStack(spacing: 8) {
                                        Image(systemName: occ.icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Color.neonCyan)
                                        Text(occ.rawValue)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(.primary)
                                    }
                                }
                                Text(wish.dateAdded.formatted(date: .long, time: .omitted))
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button { dismiss() } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.tertiarySystemFill))
                                        .frame(width: 34, height: 34)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Metadata pills row
                        HStack(spacing: 8) {
                            if let tone = toneType {
                                detailPill(tone.label, icon: tone.emoji, color: tone.color)
                            }
                            if let len = lengthType {
                                detailPill(len.rawValue, icon: len.icon, color: len.color)
                            }
                            if let name = wish.recipientName, !name.isEmpty {
                                detailPill("For \(name)", icon: "person.fill", color: Color.neonViolet)
                            }
                        }

                        Divider()

                        // Wish text
                        Text(wish.text)
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .italic()
                            .foregroundStyle(.primary.opacity(0.92))
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()

                        // Actions
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                // Copy
                                Button {
                                    UIPasteboard.general.string = wish.text
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { copied = false }
                                    }
                                } label: {
                                    HStack(spacing: 7) {
                                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 14, weight: .semibold))
                                            .contentTransition(.symbolEffect(.replace))
                                        Text(copied ? "Copied!" : "Copy Wish")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(copied ? .green : Color.neonCyan)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(copied ? Color.green.opacity(0.10) : Color.neonCyan.opacity(0.10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(copied ? Color.green.opacity(0.35) : Color.neonCyan.opacity(0.35), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                // Delete
                                Button { showDeleteConfirm = true } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.red.opacity(0.8))
                                        .frame(width: 48, height: 48)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color.red.opacity(0.08))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .confirmationDialog("Remove from favorites?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                                    Button("Remove", role: .destructive) { onDelete() }
                                    Button("Cancel", role: .cancel) {}
                                } message: {
                                    Text("This wish will be permanently removed.")
                                }
                            }

                            // Create Card
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showCardEditor = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Create Card")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(Color(hex: 0xc084fc))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(hex: 0xc084fc).opacity(0.10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color(hex: 0xc084fc).opacity(0.40), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(32)
        .presentationDragIndicator(.hidden) // we draw our own
        .fullScreenCover(isPresented: $showCardEditor) {
            CardEditorView(
                wishText: wish.text,
                occasion: wish.occasion,
                recipientName: wish.recipientName
            )
        }
    }

    private func detailPill(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.13))
        .clipShape(Capsule())
    }
}
