import Foundation

struct FavoriteWish: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let occasion: String
    let tone: String
    let length: String
    let recipientName: String?
    let dateAdded: Date

    init(text: String, occasion: HolidayType, tone: WishTone, length: WishLength, recipientName: String?) {
        self.id = UUID()
        self.text = text
        self.occasion = occasion.rawValue
        self.tone = tone.rawValue
        self.length = length.rawValue
        self.recipientName = recipientName
        self.dateAdded = Date()
    }
}
