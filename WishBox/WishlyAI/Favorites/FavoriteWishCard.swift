import SwiftUI
import UIKit

struct FavoriteWishCard: View {
    let wish: FavoriteWish
    let onDelete: () -> Void

    @EnvironmentObject var store: FavoritesStore
    @State private var showCopied = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top metadata row
            HStack(spacing: 6) {
                if let occasion = HolidayType(rawValue: wish.occasion) {
                    pill(occasion.rawValue, icon: occasion.icon, color: Color.neonCyan)
                }
                if let tone = WishTone(rawValue: wish.tone) {
                    pill(tone.rawValue, icon: tone.icon, color: tone.color)
                }
                Spacer()
                if let length = WishLength(rawValue: wish.length) {
                    Image(systemName: length.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
            }

            // Wish text
            Text(wish.text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .italic()
                .foregroundStyle(.primary.opacity(0.92))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Bottom row
            HStack(spacing: 8) {
                if let name = wish.recipientName, !name.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.neonViolet)
                        Text("For \(name)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.neonViolet)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.neonViolet.opacity(0.15))
                    .clipShape(Capsule())
                }

                Spacer()

                Text(wish.dateAdded, style: .relative)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.5))

                // Copy button
                Button {
                    UIPasteboard.general.string = wish.text
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopied = false
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
                            .frame(width: 36, height: 36)
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(showCopied ? .green : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .buttonStyle(.plain)

                // Delete button
                Button {
                    showDeleteConfirm = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
                            .frame(width: 36, height: 36)
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.red.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
                .confirmationDialog("Delete this favorite?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func pill(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold)).foregroundStyle(color)
            Text(text).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
