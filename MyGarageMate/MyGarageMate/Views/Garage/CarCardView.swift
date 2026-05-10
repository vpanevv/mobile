import SwiftUI
import UIKit

struct CarCardView: View {
    let car: Car
    let currencyCode: String

    var body: some View {
        GlassCardView(cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 18) {
                carImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(car.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 12) {
                    metric(title: "This year", value: CurrencyFormatter.string(fromMinor: car.totalSpentThisYear(currencyCode: currencyCode), currencyCode: currencyCode), symbol: "creditcard.fill")

                    Divider()

                    if let reminder = car.nextImportantReminder {
                        metric(title: "Next", value: reminder.shortDueText, symbol: reminder.reminderType.symbolName)
                    } else {
                        metric(title: "Next", value: "All clear", symbol: "checkmark.seal.fill")
                    }
                }
            }
        }
        .accessibilityLabel("\(car.displayName), \(Int(car.currentMileage)) \(car.mileageUnit)")
    }

    private var carImage: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [.accentColor.opacity(0.30), .primary.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 190)

            if let data = car.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(maxWidth: .infinity, minHeight: 190)
            }

            Text(car.make)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(14)
        }
    }

    private func metric(title: String, value: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension CarReminder {
    var shortDueText: String {
        if let dueDate {
            return dueDate.formatted(date: .abbreviated, time: .omitted)
        }
        if let dueMileage {
            return "\(dueMileage.formatted(.number.precision(.fractionLength(0)))) km"
        }
        return title
    }
}
