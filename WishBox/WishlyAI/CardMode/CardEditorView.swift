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

    // Persisted selections
    @AppStorage("cardLastBackground") private var savedBackground: String = CardBackground.auroraPurple.rawValue
    @AppStorage("cardLastFont")       private var savedFont:       String = CardFont.rounded.rawValue

    @State private var selectedBackground: CardBackground = .auroraPurple
    @State private var selectedFont:       CardFont       = .rounded

    @State private var showName: Bool = true
    @State private var cardScale: CGFloat = 0.9
    @State private var cardOpacity: Double = 0
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage? = nil
    @State private var isRendering = false
    @State private var showErrorToast = false
    @State private var showSaveSuccess = false
    @State private var savePhotoError: String? = nil

    // Shimmer phase for Share button
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top bar ───────────────────────────────────────────
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // ── Card preview ──────────────────────────────
                        cardPreview
                            .padding(.top, 20)

                        // ── Background picker ─────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("BACKGROUND")
                            backgroundPicker
                        }
                        .padding(.horizontal, 20)

                        // ── Font picker ───────────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("FONT STYLE")
                            fontPicker
                        }
                        .padding(.horizontal, 20)

                        // ── Show name toggle ──────────────────────────
                        if let name = recipientName, !name.isEmpty {
                            Toggle(isOn: $showName) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(Color(hex: 0xc084fc))
                                    Text("Show name (\(name))")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                }
                            }
                            .tint(Color(hex: 0xc084fc))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 20)
                        }

                        // Save to Photos button
                        Button { saveToPhotos() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Save to Photos")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Color(hex: 0xc084fc))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: 0xc084fc).opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }

            // ── Toasts ─────────────────────────────────────────────────
            if showErrorToast {
                toastBanner("Couldn't render card. Try again.", isError: true)
            }
            if showSaveSuccess {
                toastBanner("Saved to Photos!", isError: false)
            }
        }
        .onAppear {
            // Restore persisted selections
            selectedBackground = CardBackground(rawValue: savedBackground) ?? .auroraPurple
            selectedFont       = CardFont(rawValue: savedFont)             ?? .rounded

            // Entrance spring
            withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.72)) {
                cardScale   = 1.0
                cardOpacity = 1.0
            }
            // Shimmer loop
            startShimmer()
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = renderedImage {
                ShareSheet(items: [img])
            }
        }
    }

    // MARK: - Subviews

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

            // Share button with shimmer
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
                        // Shimmer sweep
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
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var cardPreview: some View {
        GeometryReader { geo in
            let w = geo.size.width - 64
            WishCardView(
                wishText: wishText,
                recipientName: showName ? recipientName : nil,
                occasion: occasion,
                background: selectedBackground,
                font: selectedFont,
                cardWidth: w
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .shadow(color: Color.black.opacity(0.35), radius: 32, x: 0, y: 12)
            .frame(maxWidth: .infinity)
        }
        .frame(height: (UIScreen.main.bounds.width - 64) * 1.25)
        .padding(.horizontal, 32)
    }

    private var backgroundPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CardBackground.allCases) { bg in
                    let isSelected = bg == selectedBackground

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.35)) {
                            selectedBackground = bg
                            savedBackground = bg.rawValue
                        }
                    } label: {
                        ZStack(alignment: .bottom) {
                            // Swatch
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(bg.gradient)
                                .frame(width: 56, height: 70)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                                )
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .shadow(color: isSelected ? Color.black.opacity(0.3) : .clear, radius: 6, y: 3)

                            // Checkmark
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.4), radius: 3)
                                    .offset(y: -6)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: isSelected)

                        // Name label
                        Text(bg.name)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? Color(hex: 0xc084fc) : .secondary)
                            .padding(.top, 5)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 56)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private var fontPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CardFont.allCases) { cf in
                    let isSelected = cf == selectedFont

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.72)) {
                            selectedFont = cf
                            savedFont    = cf.rawValue
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(cf.previewLabel)
                                .font(cf.font(size: 22))
                                .foregroundStyle(isSelected ? Color(hex: 0xc084fc) : .primary)
                                .frame(height: 32)
                            Text(cf.name)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(isSelected ? Color(hex: 0xc084fc) : .secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected
                                    ? Color(hex: 0xc084fc).opacity(0.12)
                                    : Color.primary.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? Color(hex: 0xc084fc).opacity(0.5) : Color.clear, lineWidth: 1.5)
                                )
                        )
                        .scaleEffect(isSelected ? 1.04 : 1.0)
                        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isError ? showErrorToast : showSaveSuccess)
    }

    // MARK: - Actions

    private func shareCard() {
        isRendering = true
        guard let image = renderCard() else {
            isRendering = false
            withAnimation { showErrorToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showErrorToast = false }
            }
            return
        }
        renderedImage = image
        isRendering = false
        showShareSheet = true
    }

    private func saveToPhotos() {
        guard let image = renderCard() else {
            withAnimation { showErrorToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showErrorToast = false }
            }
            return
        }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else { return }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                withAnimation { showSaveSuccess = true }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showSaveSuccess = false }
                }
            }
        }
    }

    /// Rasterize WishCardView at 1080×1350 (4:5) retina quality.
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
        withAnimation(
            .linear(duration: 1.8)
            .repeatForever(autoreverses: false)
            .delay(1.2)
        ) {
            shimmerPhase = 1.4
        }
    }
}
