import SwiftUI
import UIKit

/// The hero "Next up" card on Today: the single most urgent service across the
/// whole garage, personalised with the car's photo and accent.
struct NextUpHeroCard: View {
    let reminder: CarReminder
    let car: Car

    private var accent: Color { car.accentColor }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backdrop
                .frame(height: 210)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.35), .black.opacity(0.82)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("NEXT UP")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.85))

                Text(reminder.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: reminder.reminderType.symbolName)
                        .font(.footnote.weight(.bold))
                    Text(car.model)
                        .font(.subheadline.weight(.semibold))
                    if let due = dueText {
                        Text("· \(due)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.l)
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .metallicStroke(cornerRadius: Theme.Radius.card, opacity: 0.18)
        .shadow(color: accent.opacity(0.4), radius: 24, y: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next up: \(reminder.title) for \(car.model)")
    }

    @ViewBuilder
    private var backdrop: some View {
        if let data = car.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [accent, accent.opacity(0.5), Theme.canvas],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var dueText: String? {
        if let dueDate = reminder.dueDate {
            return dueDate.formatted(.relative(presentation: .named))
        }
        if let dueMileage = reminder.dueMileage {
            return "at \(dueMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)"
        }
        return nil
    }
}

/// A compact car tile for the horizontal garage strip on Today.
struct GarageStripCard: View {
    let car: Car

    private var status: CarHealthStatus { car.healthStatus }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            thumbnail
                .frame(width: 168, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(status.tint)
                        .frame(width: 10, height: 10)
                        .padding(8)
                }

            Text(car.model)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("\(car.currentMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 168, alignment: .leading)
        .padding(Theme.Spacing.s)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .metallicStroke(cornerRadius: Theme.Radius.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(car.model), \(status.title)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = car.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [car.accentColor, car.accentColor.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "car.side.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }
}
