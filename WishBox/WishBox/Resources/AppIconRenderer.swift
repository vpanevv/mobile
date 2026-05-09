import SwiftUI

/// Renders the WishBox app icon design as a SwiftUI view.
/// Used for Xcode Previews and as the source of truth for the icon shape.
struct AppIconView: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Background: radial gradient violet → indigo
                RadialGradient(
                    colors: [Color(hex: 0x6b21a8), Color(hex: 0x1a0533)],
                    center: .center,
                    startRadius: 0,
                    endRadius: s * 0.72
                )

                // Glow ring
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: s * 0.56, height: s * 0.56)

                // Gift icon
                Image(systemName: "gift.fill")
                    .font(.system(size: s * 0.42, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview("Icon 1024pt") {
    AppIconView()
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 300 * 0.2237, style: .continuous))
}
