import Foundation
import SwiftData

enum DocumentCategory: String, CaseIterable, Codable, Identifiable {
    case insurance
    case registration
    case warranty
    case manual
    case receipt
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .insurance: "Insurance"
        case .registration: "Registration"
        case .warranty: "Warranty"
        case .manual: "Manual"
        case .receipt: "Receipt"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .insurance: "shield.checkered"
        case .registration: "doc.text.fill"
        case .warranty: "checkmark.seal.fill"
        case .manual: "book.closed.fill"
        case .receipt: "receipt.fill"
        case .other: "doc.fill"
        }
    }
}

@Model
final class CarDocument {
    var id: UUID
    var title: String
    var categoryRawValue: String
    var fileData: Data
    var fileExtension: String
    var createdAt: Date
    var car: Car?

    var category: DocumentCategory {
        get { DocumentCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: DocumentCategory,
        fileData: Data,
        fileExtension: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.categoryRawValue = category.rawValue
        self.fileData = fileData
        self.fileExtension = fileExtension
        self.createdAt = createdAt
    }

    var isPDF: Bool {
        fileExtension.lowercased() == "pdf"
    }
}
