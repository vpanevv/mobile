import SwiftUI
import UIKit

struct PersonCard: View {
    let person: Person
    let onEdit:   () -> Void
    let onDelete: () -> Void
    let onGenerateNow: () -> Void

    @State private var glowPulse = false

    private var isToday:    Bool { person.daysUntil == 0 }
    private var isTomorrow: Bool { person.daysUntil == 1 }

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 14) {
                // ── Avatar ───────────────────────────────────────────
                avatar

                // ── Middle ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 5) {
                    Text(person.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        occasionPill
                    }

                    if isToday {
                        Button(action: onGenerateNow) {
                            HStack(spacing: 5) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Generate now")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Color(hex: 0xc084fc))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: 0xc084fc).opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(hex: 0xc084fc).opacity(0.35), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }

                Spacer(minLength: 0)

                // ── Right: countdown + edit ──────────────────────────
                VStack(alignment: .trailing, spacing: 4) {
                    countdownLabel
                    Text(person.shortDateLabel)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.6))

                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xc084fc).opacity(0.7))
                            .frame(width: 26, height: 26)
                            .background(Color(hex: 0xc084fc).opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isToday
                            ? Color(hex: 0xc084fc).opacity(glowPulse ? 0.55 : 0.30)
                            : Color.primary.opacity(0.07),
                        lineWidth: isToday ? 1.2 : 0.5
                    )
            )
            .shadow(
                color: isToday ? Color(hex: 0xc084fc).opacity(glowPulse ? 0.22 : 0.10) : .clear,
                radius: 16
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            guard isToday else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Subviews

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor.opacity(0.22))
                .frame(width: 46, height: 46)
            Text(initials)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(avatarColor)
        }
    }

    private var occasionPill: some View {
        HStack(spacing: 4) {
            Text(person.occasion.emoji)
                .font(.system(size: 11))
            Text(person.occasion.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xc084fc))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(hex: 0xc084fc).opacity(0.10))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var countdownLabel: some View {
        if isToday {
            Text("Today! 🎉")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0xc084fc))
        } else if isTomorrow {
            Text("Tomorrow")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        } else {
            Text("in \(person.daysUntil) days")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var initials: String {
        let parts = person.name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }

    private var avatarColor: Color {
        // Deterministic color from name hash
        let palette: [Color] = [
            Color(hex: 0x22d3ee), Color(hex: 0xa78bfa), Color(hex: 0xc084fc),
            Color(hex: 0x10b981), Color(hex: 0xf59e0b), Color(hex: 0xf43f5e),
            Color(hex: 0x6366f1), Color(hex: 0x0ea5e9)
        ]
        let hash = abs(person.name.hashValue)
        return palette[hash % palette.count]
    }
}
