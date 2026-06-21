import SwiftUI
import UIKit

struct CarCardView: View {
    let car: Car
    let profile: UserProfile

    private var status: CarHealthStatus {
        car.healthStatus
    }

    var body: some View {
        GlassCardView(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    carImage
                        .frame(height: 154)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.52)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(car.model)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text("\(car.year) \(car.make)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.82))
                                .lineLimit(1)
                        }

                        Spacer()

                        statusPill
                    }
                    .padding(14)
                }

                HStack(spacing: 12) {
                    metric(
                        title: "Mileage",
                        value: "\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)",
                        symbol: "gauge.with.dots.needle.67percent"
                    )

                    metric(
                        title: "This year",
                        value: CurrencyFormatter.string(fromMinor: car.totalSpentThisYear(currencyCode: profile.preferredCurrencyCode), currencyCode: profile.preferredCurrencyCode),
                        symbol: "creditcard.fill"
                    )
                }

                HStack(spacing: 10) {
                    Image(systemName: car.nextImportantReminder?.reminderType.symbolName ?? status.symbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor)
                        .frame(width: 30, height: 30)
                        .background(statusColor.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(car.nextImportantReminder?.title ?? status.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(car.healthSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(car.displayName), \(status.title), \(Int(car.currentMileage)) \(car.mileageUnit)")
    }

    private var carImage: some View {
        ZStack {
            LinearGradient(
                colors: [.accentColor.opacity(0.34), .primary.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let data = car.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
                    .opacity(0.92)
            }
        }
    }

    private var statusPill: some View {
        Label(status.shortTitle, systemImage: status.symbolName)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(statusColor.gradient, in: Capsule())
            .shadow(color: statusColor.opacity(0.28), radius: 8, y: 4)
    }

    private func metric(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(.tint)
                .frame(width: 26, height: 26)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusColor: Color {
        switch status {
        case .overdue: .red
        case .dueSoon: .orange
        case .allClear: .green
        case .needsSetup: .blue
        }
    }
}
