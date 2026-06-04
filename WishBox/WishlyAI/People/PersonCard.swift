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
    private var isSoon:     Bool { person.daysUntil >= 1 && person.daysUntil <= 7 }

    private let accent = Color(hex: 0xc084fc)

    var body: some View {
        Button(action: onEdit) {
            VStack(spacing: 12) {
                // ── Main row ─────────────────────────────────────────────
                HStack(spacing: 14) {
                    avatar

                    VStack(alignment: .leading, spacing: 6) {
                        Text(person.name.isEmpty ? "Unknown" : person.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        occasionPill
                    }

                    Spacer(minLength: 0)

                    countdownBlock
                }

                // ── Today: Generate-now pill ─────────────────────────────
                if isToday {
                    Button(action: onGenerateNow) {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Generate now")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(strokeStyle, lineWidth: isToday ? 1.5 : (isSoon ? 1 : 1))
            )
            .shadow(
                color: isToday ? accent.opacity(glowPulse ? 0.30 : 0.16) : .clear,
                radius: 16
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Divider()
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
        .onAppear {
            guard isToday else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Stroke

    private var strokeStyle: AnyShapeStyle {
        if isToday {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [accent.opacity(glowPulse ? 1.0 : 0.8), Color(hex: 0xa78bfa).opacity(0.5)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
        } else if isSoon {
            return AnyShapeStyle(Color.white.opacity(0.20))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.10))
        }
    }

    // MARK: - Avatar

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarGradient)
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1))
            Text(initial)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var occasionPill: some View {
        HStack(spacing: 5) {
            Text(person.occasion.emoji).font(.system(size: 12))
            Text(person.occasion.rawValue)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(accent.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Countdown block

    @ViewBuilder
    private var countdownBlock: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isToday {
                Text("Today! 🎉")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            } else if isTomorrow {
                Text("Tomorrow")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            } else if person.daysUntil <= 30 {
                Text("in \(person.daysUntil) days")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            } else {
                Text("in \(monthsAway)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.8))
            }

            Text(person.shortDateLabel)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.primary.opacity(0.5))
        }
    }

    private var monthsAway: String {
        let months = max(1, Int((Double(person.daysUntil) / 30.0).rounded()))
        return months == 1 ? "1 month" : "\(months) months"
    }

    // MARK: - Helpers

    private var initial: String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.first.map { String($0).uppercased() } ?? "U"
    }

    private var avatarGradient: LinearGradient {
        let palette: [[Color]] = [
            [Color(hex: 0x8b5cf6), Color(hex: 0x6d28d9)],  // violet
            [Color(hex: 0x6366f1), Color(hex: 0x4338ca)],  // indigo
            [Color(hex: 0xfb7185), Color(hex: 0xe11d48)],  // rose
            [Color(hex: 0xfbbf24), Color(hex: 0xd97706)],  // amber
            [Color(hex: 0x34d399), Color(hex: 0x059669)],  // emerald
            [Color(hex: 0x22d3ee), Color(hex: 0x0891b2)],  // cyan
        ]
        let idx = abs(person.name.hashValue) % palette.count
        return LinearGradient(colors: palette[idx], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
