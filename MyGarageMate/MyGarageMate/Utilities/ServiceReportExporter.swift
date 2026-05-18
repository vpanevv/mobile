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
        let margin: CGFloat = 42
        let contentWidth = pageRect.width - (margin * 2)

        try renderer.writePDF(to: fileURL) { context in
            var y = margin

            func beginPage() {
                context.beginPage()
                UIColor.white.setFill()
                UIBezierPath(rect: pageRect).fill()
                y = margin
            }

            func beginPageIfNeeded(_ neededHeight: CGFloat) {
                if y + neededHeight > pageRect.height - margin {
                    beginPage()
                }
            }

            func drawText(
                _ text: String,
                font: UIFont,
                color: UIColor = .black,
                indent: CGFloat = 0,
                spacingAfter: CGFloat = 8
            ) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let rect = CGRect(x: margin + indent, y: y, width: contentWidth - indent, height: .greatestFiniteMagnitude)
                let measured = text.boundingRect(
                    with: rect.size,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                beginPageIfNeeded(ceil(measured.height) + spacingAfter)
                text.draw(with: CGRect(x: margin + indent, y: y, width: contentWidth - indent, height: ceil(measured.height)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                y += ceil(measured.height) + spacingAfter
            }

            func drawDivider() {
                beginPageIfNeeded(14)
                UIColor.systemGray4.setStroke()
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                path.lineWidth = 1
                path.stroke()
                y += 14
            }

            func drawCarPhotoIfAvailable() {
                guard let photoData = car.photoData, let image = UIImage(data: photoData) else { return }
                beginPageIfNeeded(190)
                let imageRect = aspectFitRect(for: image.size, inside: CGRect(x: margin, y: y, width: contentWidth, height: 170))
                image.draw(in: imageRect)
                y += 184
            }

            func drawIcon(_ symbolName: String) {
                guard let image = UIImage(systemName: symbolName) else { return }
                beginPageIfNeeded(26)
                image
                    .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
                    .draw(in: CGRect(x: margin, y: y + 1, width: 18, height: 18))
            }

            beginPage()
            drawText("MyGarageMate Car Service Report", font: .systemFont(ofSize: 28, weight: .bold), spacingAfter: 6)
            drawText("Generated \(Self.displayDateTime(Date()))", font: .systemFont(ofSize: 11), color: .darkGray, spacingAfter: 18)
            drawText("\(car.year) \(car.make) \(car.model)", font: .systemFont(ofSize: 21, weight: .bold), spacingAfter: 4)
            drawText("Engine: \(car.engineType.title)", font: .systemFont(ofSize: 12), color: .darkGray, spacingAfter: 12)
            drawCarPhotoIfAvailable()

            let records = car.serviceRecords.sorted { $0.date > $1.date }
            for record in records {
                beginPageIfNeeded(170)
                drawIcon(record.category.symbolName)
                drawText(record.title, font: .systemFont(ofSize: 16, weight: .semibold), indent: 26, spacingAfter: 2)
                drawText("Type: \(record.category.title)", font: .systemFont(ofSize: 12), color: .darkGray, indent: 26, spacingAfter: 3)
                drawText("Service icon: \(record.category.symbolName)", font: .systemFont(ofSize: 12), color: .darkGray, indent: 26, spacingAfter: 8)

                let mileage = record.mileage.map { "\($0.formatted(.number.precision(.fractionLength(0)))) \(car.mileageUnit)" } ?? "Not recorded"
                let cost = CurrencyFormatter.string(fromMinor: record.amountMinor, currencyCode: record.currencyCode)
                drawText("Service date: \(Self.displayDate(record.date))", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Mileage: \(mileage)", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Cost: \(cost)", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Currency: \(record.currencyCode)", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Mechanic name: \(record.shopName ?? "Not recorded")", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Mechanic notes: \(record.notes ?? "None")", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Description: \(record.title)", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Completion status: Completed", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Created date: \(Self.displayDateTime(record.createdAt))", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Last updated date: \(Self.displayDateTime(record.updatedAt ?? record.createdAt))", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                drawText("Reminder information: \(Self.reminderSummary(for: record, in: car))", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 12)
            }

            drawDivider()
        }

        return fileURL
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

    private static func aspectFitRect(for imageSize: CGSize, inside boundingRect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return boundingRect }

        let widthRatio = boundingRect.width / imageSize.width
        let heightRatio = boundingRect.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: boundingRect.midX - fittedSize.width / 2,
            y: boundingRect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}
