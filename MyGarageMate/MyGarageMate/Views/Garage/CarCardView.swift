import SwiftUI
import UIKit

struct CarCardView: View {
    let car: Car
    let profile: UserProfile

    private let cardHeight: CGFloat = 200

    private var status: CarHealthStatus {
        car.healthStatus
    }

    private var photo: UIImage? {
        guard let data = car.photoData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            carImage
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity)
                .clipped()

            // Bottom scrim so the glass panel and text stay legible. A real
            // photo needs a heavier scrim; the branded placeholder is already
            // controlled, so it gets a lighter one.
            LinearGradient(
                colors: photo == nil
                    ? [.clear, .black.opacity(0.12), .black.opacity(0.42)]
                    : [.clear, .black.opacity(0.25), .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )

            StatusBadge(status: status, compact: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(Theme.Spacing.m)

            infoPanel
                .padding(Theme.Spacing.m)
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .metallicStroke(cornerRadius: Theme.Radius.card, opacity: 0.18)
        .shadow(color: car.accentColor.opacity(0.35), radius: 26, y: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(car.displayName), \(status.title), \(Int(car.currentMileage)) \(car.mileageUnit)")
    }

    // MARK: Photo

    @ViewBuilder
    private var carImage: some View {
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
        } else {
            placeholderArtwork
        }
    }

    /// A vivid branded backdrop for cars without a photo, so the card reads
    /// clearly instead of looking empty. A large car silhouette anchors it.
    private var placeholderArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [car.accentColor.opacity(0.85), car.accentColor.opacity(0.35), Theme.canvas],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "car.side.fill")
                .font(.system(size: 168, weight: .bold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.white.opacity(0.16))
                .rotation3DEffect(.degrees(8), axis: (x: 0, y: 1, z: 0))
                .offset(x: 28, y: 18)
                .accessibilityHidden(true)
        }
    }

    // MARK: Floating glass info panel

    private var infoPanel: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(car.model)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(car.year.description) · \(car.make)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }

                HStack(spacing: Theme.Spacing.s) {
                    GlassChip(
                        systemImage: "gauge.with.dots.needle.67percent",
                        text: "\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)",
                        tint: .white
                    )
                    GlassChip(
                        systemImage: "creditcard.fill",
                        text: CurrencyFormatter.string(
                            fromMinor: car.totalSpentThisYear(currencyCode: profile.preferredCurrencyCode),
                            currencyCode: profile.preferredCurrencyCode
                        ),
                        tint: .white
                    )
                }

                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: car.nextImportantReminder?.reminderType.symbolName ?? status.symbolName)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(status.tint.opacity(0.9), in: Circle())

                    Text(car.nextImportantReminder?.title ?? status.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control + 4, style: .continuous), overImagery: true)
        }
    }
}
