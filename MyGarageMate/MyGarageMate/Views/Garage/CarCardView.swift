import SwiftUI
import UIKit

struct CarCardView: View {
    let car: Car
    let profile: UserProfile

    private var status: CarHealthStatus {
        car.healthStatus
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            carImage
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .clipped()

            // Bottom scrim so the glass panel and text stay legible.
            LinearGradient(
                colors: [.clear, .black.opacity(0.25), .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )

            StatusBadge(status: status, compact: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(Theme.Spacing.m)

            infoPanel
                .padding(Theme.Spacing.m)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: status.tint.opacity(0.28), radius: 22, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(car.displayName), \(status.title), \(Int(car.currentMileage)) \(car.mileageUnit)")
    }

    // MARK: Photo

    private var carImage: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.accent.opacity(0.45), Theme.mist.opacity(0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let data = car.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 76, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: Floating glass info panel

    private var infoPanel: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(car.model)
                        .font(.title2.weight(.bold))
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
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.Radius.control + 4, style: .continuous))
        }
    }
}
