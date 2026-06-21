import Foundation
import UIKit

enum ServiceReportExporter {
    enum ExportError: LocalizedError {
        case noServiceRecordsForCar

        var errorDescription: String? {
            switch self {
            case .noServiceRecordsForCar:
                "No service records available for this car."
            }
        }
    }

    static func makePDF(for car: Car) throws -> URL {
        guard !car.serviceRecords.isEmpty else {
            throw ExportError.noServiceRecordsForCar
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MyGarageMate-\(Self.fileSafeName(car.make))-\(Self.fileSafeName(car.model))-Service-Report-\(Self.fileStamp()).pdf")

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let margin: CGFloat = 36
        let contentWidth = pageRect.width - (margin * 2)
        let blue = UIColor(red: 0.05, green: 0.42, blue: 0.86, alpha: 1)
        let ink = UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        let muted = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1)
        let paper = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)

        try renderer.writePDF(to: fileURL) { context in
            var y = margin

            func beginPage() {
                context.beginPage()
                paper.setFill()
                UIBezierPath(rect: pageRect).fill()
                y = margin
            }

            func beginPageIfNeeded(_ height: CGFloat) {
                if y + height > pageRect.height - margin {
                    beginPage()
                }
            }

            func drawText(
                _ text: String,
                font: UIFont,
                color: UIColor = ink,
                rect: CGRect,
                alignment: NSTextAlignment = .left
            ) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                paragraph.alignment = alignment
                text.draw(
                    with: rect,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [
                        .font: font,
                        .foregroundColor: color,
                        .paragraphStyle: paragraph
                    ],
                    context: nil
                )
            }

            func measuredHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
                let rect = text.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font],
                    context: nil
                )
                return ceil(rect.height)
            }

            func drawCard(_ rect: CGRect, radius: CGFloat = 18, fill: UIColor = .white) {
                fill.setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
            }

            func drawHeader() {
                let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 178)
                drawCard(headerRect, radius: 24, fill: blue)

                if let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [
                        UIColor.white.withAlphaComponent(0.22).cgColor,
                        UIColor.black.withAlphaComponent(0.16).cgColor
                    ] as CFArray,
                    locations: [0, 1]
                ) {
                    context.cgContext.saveGState()
                    UIBezierPath(roundedRect: headerRect, cornerRadius: 24).addClip()
                    context.cgContext.drawLinearGradient(
                        gradient,
                        start: CGPoint(x: headerRect.minX, y: headerRect.minY),
                        end: CGPoint(x: headerRect.maxX, y: headerRect.maxY),
                        options: []
                    )
                    context.cgContext.restoreGState()
                }

                drawText(
                    "MyGarageMate",
                    font: .systemFont(ofSize: 15, weight: .semibold),
                    color: .white.withAlphaComponent(0.84),
                    rect: CGRect(x: headerRect.minX + 24, y: headerRect.minY + 22, width: 220, height: 22)
                )
                drawText(
                    "Service Report",
                    font: .systemFont(ofSize: 34, weight: .bold),
                    color: .white,
                    rect: CGRect(x: headerRect.minX + 24, y: headerRect.minY + 50, width: 310, height: 44)
                )
                drawText(
                    car.displayName,
                    font: .systemFont(ofSize: 19, weight: .semibold),
                    color: .white,
                    rect: CGRect(x: headerRect.minX + 24, y: headerRect.minY + 104, width: 310, height: 26)
                )
                drawText(
                    "Generated \(displayDateTime(Date()))",
                    font: .systemFont(ofSize: 11, weight: .medium),
                    color: .white.withAlphaComponent(0.74),
                    rect: CGRect(x: headerRect.minX + 24, y: headerRect.minY + 134, width: 310, height: 18)
                )

                let imageRect = CGRect(x: headerRect.maxX - 164, y: headerRect.minY + 24, width: 122, height: 122)
                if let photoData = car.photoData, let image = UIImage(data: photoData) {
                    context.cgContext.saveGState()
                    UIBezierPath(roundedRect: imageRect, cornerRadius: 24).addClip()
                    image.draw(in: aspectFillRect(for: image.size, inside: imageRect))
                    context.cgContext.restoreGState()
                } else if let image = UIImage(systemName: "car.side.fill") {
                    UIColor.white.withAlphaComponent(0.18).setFill()
                    UIBezierPath(roundedRect: imageRect, cornerRadius: 24).fill()
                    image.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: imageRect.insetBy(dx: 24, dy: 34))
                }

                y += headerRect.height + 18
            }

            func drawSummaryCards() {
                let records = car.serviceRecords
                let lastService = car.lastService?.title ?? "None"
                let totals = totalsByCurrency(for: records)
                    .map { "\($0.key) \(CurrencyFormatter.string(fromMinor: $0.value, currencyCode: $0.key))" }
                    .sorted()
                    .joined(separator: "  ")

                let items: [(String, String, String)] = [
                    ("Health", car.healthStatus.title, car.healthStatus.symbolName),
                    ("Records", "\(records.count)", "list.bullet.rectangle.fill"),
                    ("Last service", lastService, "wrench.and.screwdriver.fill"),
                    ("Total spend", totals.isEmpty ? "€0.00" : totals, "creditcard.fill")
                ]

                let gap: CGFloat = 10
                let cardWidth = (contentWidth - gap) / 2
                let cardHeight: CGFloat = 82

                for index in items.indices {
                    let row = CGFloat(index / 2)
                    let column = CGFloat(index % 2)
                    let rect = CGRect(
                        x: margin + column * (cardWidth + gap),
                        y: y + row * (cardHeight + gap),
                        width: cardWidth,
                        height: cardHeight
                    )
                    drawCard(rect)
                    if let icon = UIImage(systemName: items[index].2) {
                        icon.withTintColor(blue, renderingMode: .alwaysOriginal)
                            .draw(in: CGRect(x: rect.minX + 16, y: rect.minY + 15, width: 20, height: 20))
                    }
                    drawText(items[index].0, font: .systemFont(ofSize: 10, weight: .medium), color: muted, rect: CGRect(x: rect.minX + 16, y: rect.minY + 42, width: rect.width - 32, height: 14))
                    drawText(items[index].1, font: .systemFont(ofSize: 15, weight: .bold), color: ink, rect: CGRect(x: rect.minX + 16, y: rect.minY + 57, width: rect.width - 32, height: 20))
                }

                y += (cardHeight * 2) + gap + 24
            }

            func drawSectionTitle(_ title: String) {
                beginPageIfNeeded(34)
                drawText(title, font: .systemFont(ofSize: 19, weight: .bold), rect: CGRect(x: margin, y: y, width: contentWidth, height: 24))
                y += 34
            }

            func drawMonthlyBars() {
                let months = car.monthlySpend(currencyCode: "EUR")
                guard months.contains(where: { $0.amountMinor > 0 }) else { return }

                drawSectionTitle("Spend trend")
                let rect = CGRect(x: margin, y: y, width: contentWidth, height: 142)
                drawCard(rect)

                let maxAmount = max(months.map(\.amountMinor).max() ?? 1, 1)
                let barArea = rect.insetBy(dx: 22, dy: 20)
                let barWidth = (barArea.width - CGFloat(months.count - 1) * 12) / CGFloat(months.count)

                for (index, month) in months.enumerated() {
                    let ratio = CGFloat(month.amountMinor) / CGFloat(maxAmount)
                    let height = max(8, ratio * 72)
                    let x = barArea.minX + CGFloat(index) * (barWidth + 12)
                    let barRect = CGRect(x: x, y: barArea.maxY - 32 - height, width: barWidth, height: height)
                    blue.withAlphaComponent(month.amountMinor == 0 ? 0.18 : 0.88).setFill()
                    UIBezierPath(roundedRect: barRect, cornerRadius: 5).fill()
                    drawText(month.shortMonth, font: .systemFont(ofSize: 9, weight: .semibold), color: muted, rect: CGRect(x: x - 4, y: barArea.maxY - 22, width: barWidth + 8, height: 14), alignment: .center)
                }

                y += rect.height + 24
            }

            func drawRecord(_ record: ServiceRecord, isLast: Bool) {
                let notes = record.notes ?? "None"
                let shopName = record.shopName ?? "Not recorded"
                let mileage = record.mileage.map { "\($0.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)" } ?? "Not recorded"
                let reminder = reminderSummary(for: record, in: car)
                let details = [
                    "Type: \(record.category.title)",
                    "Service date: \(displayDate(record.date))",
                    "Mileage: \(mileage)",
                    "Cost: \(CurrencyFormatter.string(fromMinor: record.amountMinor, currencyCode: record.currencyCode))",
                    "Mechanic: \(shopName)",
                    "Notes: \(notes)",
                    "Reminder: \(reminder)",
                    "Created: \(displayDateTime(record.createdAt))",
                    "Updated: \(displayDateTime(record.updatedAt ?? record.createdAt))"
                ]

                let detailHeight = details.reduce(CGFloat(0)) { partial, text in
                    partial + measuredHeight(text, font: .systemFont(ofSize: 10), width: contentWidth - 84) + 4
                }
                let cardHeight = max(126, detailHeight + 54)
                beginPageIfNeeded(cardHeight + 16)

                let cardRect = CGRect(x: margin + 36, y: y, width: contentWidth - 36, height: cardHeight)
                drawCard(cardRect)

                if !isLast {
                    UIColor.systemGray4.setStroke()
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: margin + 18, y: y + 42))
                    path.addLine(to: CGPoint(x: margin + 18, y: y + cardHeight + 16))
                    path.lineWidth = 2
                    path.stroke()
                }

                blue.setFill()
                UIBezierPath(ovalIn: CGRect(x: margin, y: y + 10, width: 36, height: 36)).fill()
                if let icon = UIImage(systemName: record.category.symbolName) {
                    icon.withTintColor(.white, renderingMode: .alwaysOriginal)
                        .draw(in: CGRect(x: margin + 9, y: y + 19, width: 18, height: 18))
                }

                drawText(record.title, font: .systemFont(ofSize: 16, weight: .bold), rect: CGRect(x: cardRect.minX + 16, y: cardRect.minY + 14, width: cardRect.width - 32, height: 22))

                var detailY = cardRect.minY + 44
                for detail in details {
                    let height = measuredHeight(detail, font: .systemFont(ofSize: 10), width: cardRect.width - 32)
                    drawText(detail, font: .systemFont(ofSize: 10), color: muted, rect: CGRect(x: cardRect.minX + 16, y: detailY, width: cardRect.width - 32, height: height + 2))
                    detailY += height + 4
                }

                y += cardHeight + 16
            }

            beginPage()
            drawHeader()
            drawSummaryCards()
            drawMonthlyBars()
            drawSectionTitle("Service timeline")

            let records = car.serviceRecords.sorted { $0.date > $1.date }
            for (index, record) in records.enumerated() {
                drawRecord(record, isLast: index == records.count - 1)
            }
        }

        return fileURL
    }

    private static func totalsByCurrency(for records: [ServiceRecord]) -> [String: Int] {
        records.reduce(into: [:]) { result, record in
            result[record.currencyCode, default: 0] += record.amountMinor
        }
    }

    private static func reminderSummary(for record: ServiceRecord, in car: Car) -> String {
        let matchingTypes: [ReminderType]
        switch record.category {
        case .oil:
            matchingTypes = [.oilChange]
        case .tires:
            matchingTypes = [.tireChange]
        case .insurance:
            matchingTypes = [.insurance]
        case .inspection:
            matchingTypes = [.inspection]
        default:
            matchingTypes = []
        }

        let reminders = car.reminders
            .filter { matchingTypes.contains($0.reminderType) }
            .sorted(by: CarReminder.sortUpcoming)

        guard !reminders.isEmpty else { return "None" }

        return reminders.map { reminder in
            var parts = ["\(reminder.title) (\(reminder.reminderType.title))"]
            if let dueDate = reminder.dueDate {
                parts.append("due \(displayDate(dueDate))")
            }
            if let dueMileage = reminder.dueMileage {
                parts.append("at \(dueMileage.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)")
            }
            if let reminderDate = reminder.reminderDate {
                parts.append("notification \(displayDate(reminderDate))")
            }
            parts.append(reminder.isCompleted ? "completed" : "incomplete")
            return parts.joined(separator: ", ")
        }
        .joined(separator: "; ")
    }

    private static func displayDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private static func displayDateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private static func fileStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private static func fileSafeName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return value
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
    }

    private static func aspectFillRect(for imageSize: CGSize, inside boundingRect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return boundingRect }

        let widthRatio = boundingRect.width / imageSize.width
        let heightRatio = boundingRect.height / imageSize.height
        let scale = max(widthRatio, heightRatio)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: boundingRect.midX - fittedSize.width / 2,
            y: boundingRect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}
