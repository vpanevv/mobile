import SwiftUI

struct SpendInsightsView: View {
    let car: Car
    let currencyCode: String

    private var months: [MonthlySpend] {
        car.monthlySpend(currencyCode: currencyCode)
    }

    private var maxAmount: Int {
        max(months.map(\.amountMinor).max() ?? 0, 1)
    }

    private var yearlyTotal: Int {
        car.totalSpentThisYear(currencyCode: currencyCode)
    }

    var body: some View {
        GlassCardView(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Spend insights", systemImage: "chart.bar.xaxis")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Last 6 months")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(CurrencyFormatter.string(fromMinor: yearlyTotal, currencyCode: currencyCode))
                            .font(.headline.weight(.bold))
                        Text("This year")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(months) { month in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(month.amountMinor == 0 ? Color.secondary.opacity(0.18) : Color.accentColor.gradient)
                                .frame(height: barHeight(for: month.amountMinor))
                                .frame(maxWidth: .infinity)

                            Text(month.shortMonth)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .accessibilityLabel("\(month.shortMonth), \(CurrencyFormatter.string(fromMinor: month.amountMinor, currencyCode: currencyCode))")
                    }
                }
                .frame(height: 112)

                if yearlyTotal == 0 {
                    Text("Add a paid service to start seeing cost trends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func barHeight(for amount: Int) -> CGFloat {
        let ratio = CGFloat(amount) / CGFloat(maxAmount)
        return max(10, ratio * 82)
    }
}
