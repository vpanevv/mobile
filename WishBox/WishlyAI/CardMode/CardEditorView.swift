import SwiftUI
import UIKit
import Photos

// MARK: - CardEditorView

struct CardEditorView: View {
    let wishText: String
    let occasion: String
    let recipientName: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("cardLastBackground") private var savedBackground: String = CardBackground.auroraPurple.rawValue
    @AppStorage("cardLastFont")       private var savedFont:       String = CardFont.rounded.rawValue
    @AppStorage("wishlyai.isDark")    private var isDark: Bool = true

    @State private var selectedBackground: CardBackground = .auroraPurple
    @State private var selectedFont:       CardFont       = .rounded
    @State private var showName: Bool = true
    @State private var cardScale:   CGFloat = 0.9
    @State private var cardOpacity: Double  = 0
    @State private var showShareSheet  = false
    @State private var renderedImage:  UIImage? = nil
    @State private var isRendering     = false
    @State private var showErrorToast  = false
    @State private var showSaveSuccess = false
    @State private var shimmerPhase:   CGFloat = -1

    var body: some View {
        ZStack {
            // ── Atmosphere ─────────────────────────────────────────────
            NeuralBackground().ignoresSafeArea()
            FlowAmbientLayer()
            ParticleSystemView()

            // ── Layout ─────────────────────────────────────────────────
            VStack(spacing: 0) {
                topBar

                GeometryReader { geo in
                    VStack(spacing: 12) {
                        // Card preview — derive cardWidth from a capped height so
                        // WishCardView's internal frame is correct from the start.
                        // Target: card takes ≤ 38 % of available height, max 260 pt wide.
                        let maxCardH = min(geo.size.height * 0.38, 310)
                        let cardW    = min(maxCardH / 1.25, geo.size.width - 80)

                        WishCardView(
                            wishText: wishText,
                            recipientName: showName ? recipientName : nil,
                            occasion: occasion,
                            background: selectedBackground,
                            font: selectedFont,
                            cardWidth: cardW           // WishCardView self-sizes from this
                        )
                        .scaleEffect(cardScale)
                        .opacity(cardOpacity)
                        .shadow(color: .black.opacity(0.42), radius: 24, y: 10)
                        .frame(maxWidth: .infinity)

                        // ── Controls ───────────────────────────────────
                        VStack(spacing: 10) {

                            // Background
                            VStack(alignment: .leading, spacing: 7) {
                                controlLabel("BACKGROUND")
                                backgroundPicker
                            }

                            // Font
                            VStack(alignment: .leading, spacing: 7) {
                                controlLabel("FONT STYLE")
                                fontPicker
                            }

                            // Name toggle (only when a name exists)
                            if let name = recipientName, !name.isEmpty {
                                Toggle(isOn: $showName) {
                                    HStack(spacing: 7) {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(Color(hex: 0xc084fc))
                                            .font(.system(size: 13))
                                        Text("Show name (\(name))")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                    }
                                }
                                .tint(Color(hex: 0xc084fc))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                            }

                            // Save to Photos
                            Button { saveToPhotos() } label: {
                                HStack(spacing: 7) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Save to Photos")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(Color(hex: 0xc084fc))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(Color(hex: 0xc084fc).opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 14)
                }
            }

            // ── Toasts ─────────────────────────────────────────────────
            if showErrorToast  { toastBanner("Couldn't render card. Try again.", isError: true) }
            if showSaveSuccess { toastBanner("Saved to Photos!", isError: false) }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .onAppear {
            // Restore last-used background, but override with a thematic default for
            // Valentine's Day when the user hasn't previously picked something themselves.
            let restoredBG = CardBackground(rawValue: savedBackground) ?? .auroraPurple
            if occasion.lowercased().contains("valentine") && savedBackground == CardBackground.auroraPurple.rawValue {
                selectedBackground = .sunsetRose
            } else {
                selectedBackground = restoredBG
            }
            selectedFont = CardFont(rawValue: savedFont) ?? .rounded
            withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.72)) {
                cardScale   = 1.0
                cardOpacity = 1.0
            }
            startShimmer()
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = renderedImage { ShareSheet(items: [img]) }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            Text("Create Card")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                shareCard()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Share")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: 0x9333ea), Color(hex: 0xc084fc)],
                            startPoint: .leading, endPoint: .trailing
                        )
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.25), .clear],
                            startPoint: .init(x: shimmerPhase, y: 0),
                            endPoint: .init(x: shimmerPhase + 0.4, y: 0)
                        )
                    }
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: 0xc084fc).opacity(0.45), radius: 10, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(isRendering)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    // MARK: - Background picker (compact swatches, no labels)

    private var backgroundPicker: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(CardBackground.allCases) { bg in
                let isSelected = bg == selectedBackground
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.72)) {
                        selectedBackground = bg
                        savedBackground = bg.rawValue
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(bg.gradient)
                        .aspectRatio(0.82, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                        )
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.35), radius: 3)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .shadow(color: isSelected ? .black.opacity(0.28) : .clear, radius: 5, y: 2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Font picker (equal-width chips)

    private var fontPicker: some View {
        HStack(spacing: 6) {
            ForEach(CardFont.allCases) { cf in
                let isSelected = cf == selectedFont
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.72)) {
                        selectedFont = cf
                        savedFont    = cf.rawValue
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(cf.previewLabel)
                            .font(cf.font(size: 18))
                            .foregroundStyle(isSelected ? Color(hex: 0xc084fc) : .primary)
                            .frame(height: 24)
                        Text(cf.name)
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? Color(hex: 0xc084fc) : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(isSelected
                                ? Color(hex: 0xc084fc).opacity(0.14)
                                : Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(isSelected ? Color(hex: 0xc084fc).opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .scaleEffect(isSelected ? 1.04 : 1.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func controlLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .tracking(1.5)
    }

    private func toastBanner(_ message: String, isError: Bool) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isError ? Color.red.opacity(0.88) : Color(hex: 0x059669).opacity(0.9))
                .clipShape(Capsule())
                .shadow(radius: 12)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showErrorToast || showSaveSuccess)
    }

    // MARK: - Actions

    private func shareCard() {
        isRendering = true
        guard let image = renderCard() else {
            isRendering = false
            withAnimation { showErrorToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showErrorToast = false } }
            return
        }
        renderedImage = image
        isRendering = false
        showShareSheet = true
    }

    private func saveToPhotos() {
        guard let image = renderCard() else {
            withAnimation { showErrorToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showErrorToast = false } }
            return
        }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else { return }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                withAnimation { showSaveSuccess = true }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showSaveSuccess = false } }
            }
        }
    }

    private func renderCard() -> UIImage? {
        let renderer = ImageRenderer(
            content: WishCardView(
                wishText: wishText,
                recipientName: showName ? recipientName : nil,
                occasion: occasion,
                background: selectedBackground,
                font: selectedFont,
                cardWidth: 1080
            )
            .frame(width: 1080, height: 1350)
        )
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private func startShimmer() {
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false).delay(1.2)) {
            shimmerPhase = 1.4
        }
    }
}
