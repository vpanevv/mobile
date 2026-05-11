import SwiftUI
import UIKit

struct CarCardView: View {
    let car: Car

    var body: some View {
        GlassCardView(cornerRadius: 22) {
            HStack(spacing: 14) {
                carImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(car.model)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(car.year) \(car.make)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityLabel("\(car.displayName), \(Int(car.currentMileage)) \(car.mileageUnit)")
    }

    private var carImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [.accentColor.opacity(0.30), .primary.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 96, height: 72)

            if let data = car.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 96, height: 72)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
    }
}
