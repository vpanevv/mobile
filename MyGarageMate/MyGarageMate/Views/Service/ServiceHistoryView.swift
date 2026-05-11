import SwiftData
import SwiftUI

struct ServiceHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car
    @State private var recordPendingDeletion: ServiceRecord?

    var body: some View {
        Group {
            if car.serviceRecordsNewestFirst.isEmpty {
                EmptyStateView(
                    symbolName: "wrench.and.screwdriver",
                    title: "No service history yet",
                    message: "Add oil changes, repairs, insurance, inspections, and receipts as they happen."
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(car.serviceRecordsNewestFirst, id: \.id) { record in
                        serviceRow(record)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    recordPendingDeletion = record
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    recordPendingDeletion = record
                                } label: {
                                    Label("Delete Service", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete service record?",
            isPresented: Binding(
                get: { recordPendingDeletion != nil },
                set: { if !$0 { recordPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Record", role: .destructive) {
                deletePendingRecord()
            }
            Button("Cancel", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: {
            Text("This removes the selected service record from this device.")
        }
    }

    private func deletePendingRecord() {
        guard let record = recordPendingDeletion else { return }
        modelContext.delete(record)
        do {
            try modelContext.save()
            HapticsManager.warning()
        } catch {
            assertionFailure("Failed to delete service record: \(error)")
        }
        recordPendingDeletion = nil
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

            Button(role: .destructive) {
                recordPendingDeletion = record
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(width: 34, height: 34)
                    .background(.red.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(record.title)")
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
