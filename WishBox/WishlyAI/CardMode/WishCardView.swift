import SwiftUI

// MARK: - WishCardView
// Renders identically on-screen (preview) and off-screen (ImageRenderer export).
// Pass an explicit `cardWidth` so the off-screen render at 1080pt matches the preview.

struct WishCardView: View {
    let wishText: String
    let recipientName: String?
    let occasion: String
    let background: CardBackground
    let font: CardFont

    /// Override the card width for high-res export (default fits screen).
    var cardWidth: CGFloat = 320

    private var cardHeight: CGFloat { cardWidth * 1.25 }       // 4:5

    var body: some View {
        ZStack {
            // ── Background gradient ──────────────────────────────────────
            background.gradient
                .ignoresSafeArea()

            // ── Subtle liquid-glass depth blobs ──────────────────────────
            depthLayer

            // ── Content ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // Occasion label
                Text(occasion.uppercased())
                    .tracking(2.5)
                    .font(.system(size: cardWidth * 0.033, weight: .semibold, design: .rounded))
                    .foregroundStyle(background.preferredTextColor.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, cardWidth * 0.1)
                    .padding(.bottom, cardWidth * 0.05)

                // Decorative rule
                Rectangle()
                    .fill(background.preferredTextColor.opacity(0.25))
                    .frame(width: cardWidth * 0.18, height: 1)
                    .padding(.bottom, cardWidth * 0.06)

                // Wish text
                Text(wishText)
                    .font(font.font(size: cardWidth * 0.075))
                    .foregroundStyle(background.preferredTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(cardWidth * 0.022)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, cardWidth * 0.1)

                // Recipient name
                if let name = recipientName, !name.isEmpty {
                    Text("— for \(name)")
                        .font(.system(size: cardWidth * 0.045, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(background.preferredTextColor.opacity(0.72))
                        .padding(.top, cardWidth * 0.045)
                }

                Spacer(minLength: 0)

                // Watermark
                Text("Made with WishlyAI ✨")
                    .font(.system(size: cardWidth * 0.033, weight: .medium, design: .rounded))
                    .foregroundStyle(background.preferredTextColor.opacity(0.35))
                    .padding(.bottom, cardWidth * 0.06)
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cardWidth * 0.078, style: .continuous))
    }

    // Blurred white circles for depth — subtle liquid-glass feel
    @ViewBuilder
    private var depthLayer: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: cardWidth * 0.9)
                .blur(radius: cardWidth * 0.12)
                .offset(x: -cardWidth * 0.22, y: -cardHeight * 0.28)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: cardWidth * 0.7)
                .blur(radius: cardWidth * 0.09)
                .offset(x: cardWidth * 0.3, y: cardHeight * 0.3)
        }
    }
}
