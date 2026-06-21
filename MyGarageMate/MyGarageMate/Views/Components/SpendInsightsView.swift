import Charts
import SwiftUI

/// Interactive spend analytics for a single car, built on Swift Charts:
/// a selectable 6-month trend and a category breakdown donut.
struct SpendInsightsView: View {
    let car: Car
    let currencyCode: String

    @State private var selectedMonth: String?

    private var months: [MonthlySpend] {
        car.monthlySpend(currencyCode: currencyCode)
    }

    private var categories: [CategorySpend] {
        car.spendByCategoryThisYear(currencyCode: currencyCode)
    }

    private var yearlyTotal: Int {
        car.totalSpentThisYear(currencyCode: currencyCode)
    }

    private var selectedSpend: MonthlySpend? {
        guard let selectedMonth else { return nil }
        return months.first { $0.shortMonth == selectedMonth }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            trendCard
            if !categories.isEmpty {
                categoryCard
            }
        }
    }

    // MARK: Trend

    private var trendCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                SectionHeader(
                    "Spend insights",
                    systemImage: "chart.bar.xaxis",
                    subtitle: selectedSpend != nil ? "Tap a bar for detail" : "Last 6 months"
                ) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CurrencyFormatter.string(fromMinor: selectedSpend?.amountMinor ?? yearlyTotal, currencyCode: currencyCode))
                            .font(.title3.weight(.bold))
                            .contentTransition(.numericText())
                            .animation(Motion.snappy, value: selectedSpend?.amountMinor)
                        Text(selectedSpend.map { $0.monthStart.formatted(.dateTime.month(.wide)) } ?? "This year")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Chart(months) { month in
                    BarMark(
                        x: .value("Month", month.shortMonth),
                        y: .value("Spent", month.amountMinor)
                    )
                    .foregroundStyle(barStyle(for: month))
                    .cornerRadius(8)
                }
                .chartXSelection(value: $selectedMonth)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let minor = value.as(Int.self) {
                                Text(CurrencyFormatter.compactString(fromMinor: minor, currencyCode: currencyCode))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 150)
                .animation(Motion.snappy, value: selectedMonth)

                if yearlyTotal == 0 {
                    Text("Add a paid service to start seeing cost trends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func barStyle(for month: MonthlySpend) -> AnyShapeStyle {
        if month.amountMinor == 0 {
            return AnyShapeStyle(Color.secondary.opacity(0.18))
        }
        if let selectedMonth, selectedMonth != month.shortMonth {
            return AnyShapeStyle(Theme.accent.opacity(0.35))
        }
        return AnyShapeStyle(Theme.accent.gradient)
    }

    // MARK: Categories

    private var categoryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                SectionHeader("By category", systemImage: "chart.pie.fill", subtitle: "This year")

                HStack(spacing: Theme.Spacing.l) {
                    donut
                        .frame(width: 132, height: 132)

                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        ForEach(categories.prefix(5)) { item in
                            HStack(spacing: Theme.Spacing.s) {
                                Circle()
                                    .fill(item.category.tint)
                                    .frame(width: 9, height: 9)
                                Text(item.category.title)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                                Spacer(minLength: Theme.Spacing.s)
                                Text(CurrencyFormatter.string(fromMinor: item.amountMinor, currencyCode: currencyCode))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var donut: some View {
        Chart(categories) { item in
            SectorMark(
                angle: .value("Spent", item.amountMinor),
                innerRadius: .ratio(0.62),
                angularInset: 2
            )
            .foregroundStyle(item.category.tint)
            .cornerRadius(4)
        }
        .chartBackground { _ in
            VStack(spacing: 0) {
                Text("\(categories.count)")
                    .font(.title3.weight(.bold))
                Text(categories.count == 1 ? "type" : "types")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
