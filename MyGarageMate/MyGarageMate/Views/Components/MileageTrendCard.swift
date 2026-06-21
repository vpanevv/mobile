import Charts
import SwiftUI

/// A line chart of recorded mileage over time, showing how the car accrues distance.
struct MileageTrendCard: View {
    let car: Car

    private var points: [MileagePoint] {
        car.mileageHistory()
    }

    var body: some View {
        if points.count >= 2 {
            GlassCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    SectionHeader("Mileage trend", systemImage: "gauge.with.dots.needle.67percent", subtitle: "Recorded over time")

                    Chart(points) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Mileage", point.mileage)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.35), Theme.accent.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Mileage", point.mileage)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Mileage", point.mileage)
                        )
                        .foregroundStyle(Theme.accent)
                        .symbolSize(36)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let mileage = value.as(Double.self) {
                                    Text(mileage.formatted(.number.notation(.compactName)))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 140)
                }
            }
        }
    }
}
