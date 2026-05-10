import SwiftData
import SwiftUI

struct ServiceHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car

    var body: some View {
        if car.serviceRecordsNewestFirst.isEmpty {
            EmptyStateView(
                symbolName: "wrench.and.screwdriver",
                title: "No service history yet",
                message: "Add oil changes, repairs, insurance, inspections, and receipts as they happen."
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(car.serviceRecordsNewestFirst) { record in
                    serviceRow(record)
                        .swipeActions {
                            Button(role: .destructive) {
                                modelContext.delete(record)
                                HapticsManager.warning()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func serviceRow(_ record: ServiceRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.category.symbolName)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(record.title)
                    .font(.headline)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let shopName = record.shopName {
                    Text(shopName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            CurrencyAmountView(amountMinor: record.amountMinor, currencyCode: record.currencyCode)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
